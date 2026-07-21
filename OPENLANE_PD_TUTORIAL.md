# Tutorial physical design CPU 4-bit với OpenLane 2

Tài liệu này hướng dẫn chạy physical design theo từng nhóm công đoạn, từ RTL đến GDSII. OpenLane quản lý dữ liệu trung gian và gọi các công cụ chuyên dụng, còn người thiết kế chủ động quyết định cấu hình, vị trí I/O pin, điểm dừng và thời điểm tiếp tục flow.

## 1. Phạm vi thiết kế

Top-level dùng cho physical design là `cpu_4bit`:

| Port | Hướng | Chức năng |
|---|---|---|
| `clk` | Input | Clock CPU |
| `rst_n` | Input | Reset bất đồng bộ, active-low |
| `imem_rdata[7:0]` | Input | Instruction đọc từ program memory ngoài CPU |
| `imem_addr[3:0]` | Output | Địa chỉ instruction do CPU phát ra |
| `halted` | Output | Báo CPU đã thực hiện lệnh HLT |

Program memory không nằm trong CPU core. Vì vậy `tb.sv`, `program_rom.sv` và `memory/program.hex` chỉ phục vụ mô phỏng, không được đưa vào OpenLane.

Luồng dữ liệu instruction:

```text
CPU: imem_addr[3:0] ──> program memory
CPU: imem_rdata[7:0] <── program memory
```

## 2. Các file dùng cho physical design

```text
cpu_4bit/
├── alu_4bit.sv
├── control_unit.sv
├── cpu_4bit.sv
├── config.json
├── pin_order.cfg
└── OPENLANE_PD_TUTORIAL.md
```

Các file mô phỏng vẫn được giữ trong project nhưng không được liệt kê trong `config.json`:

```text
tb.sv
program_rom.sv
memory/program.hex
```

## 3. Kiểm tra RTL trước physical design

Chạy regression bằng Xcelium từ thư mục project:

```bash
cd ~/Workspaces/cpu_4bit

xrun -64bit -sv -clean -timescale 1ns/1ps \
  -f filelist.f \
  -top cpu_4bit_tb
```

Kết quả mong đợi:

```text
TEST PASSED: ACC = 6
```

Physical design không sửa lỗi chức năng RTL. Chỉ bắt đầu OpenLane sau khi mô phỏng pass.

## 4. Hiểu `config.json`

Cấu hình ban đầu:

```json
{
  "meta": {
    "version": 2,
    "flow": "Classic"
  },

  "PDK": "sky130A",
  "STD_CELL_LIBRARY": "sky130_fd_sc_hd",

  "DESIGN_NAME": "cpu_4bit",
  "VERILOG_FILES": [
    "dir::alu_4bit.sv",
    "dir::control_unit.sv",
    "dir::cpu_4bit.sv"
  ],

  "CLOCK_PORT": "clk",
  "CLOCK_PERIOD": 20.0,

  "FP_CORE_UTIL": 35,
  "FP_PIN_ORDER_CFG": "dir::pin_order.cfg",
  "ERRORS_ON_UNMATCHED_IO": "both"
}
```

Ý nghĩa các trường:

- `meta.version: 2`: bật schema cấu hình OpenLane 2 với kiểm tra kiểu dữ liệu chặt chẽ.
- `meta.flow: Classic`: chọn flow RTL-to-GDSII tiêu chuẩn.
- `PDK: sky130A`: dùng process design kit SkyWater 130 nm.
- `STD_CELL_LIBRARY: sky130_fd_sc_hd`: dùng thư viện standard cell high-density của Sky130.
- `DESIGN_NAME`: phải trùng chính xác với `module cpu_4bit`.
- `VERILOG_FILES`: chỉ chứa RTL có thể tổng hợp. `dir::` tham chiếu tương đối từ thư mục chứa `config.json`.
- `CLOCK_PORT: clk`: khai báo clock chính để OpenLane tạo timing constraint và clock tree.
- `CLOCK_PERIOD: 20.0`: mục tiêu clock 20 ns, tương đương 50 MHz.
- `FP_CORE_UTIL: 35`: cell logic dự kiến chiếm 35% core; phần còn lại dành cho routing và tối ưu timing.
- `FP_PIN_ORDER_CFG`: dùng file do người thiết kế định nghĩa cạnh và thứ tự I/O pin.
- `ERRORS_ON_UNMATCHED_IO: both`: dừng flow nếu port trong RTL và pin trong file cấu hình không khớp nhau.

JSON chuẩn không cho phép comment. Không thêm `// ...` hoặc `/* ... */` vào `config.json`.

## 5. Pin placement do người thiết kế quyết định

File `pin_order.cfg` bố trí pin như sau:

```text
                     NORTH
                imem_addr[3:0]
                       ▲
                       │
        ┌──────────────────────────┐
  clk ──┤                          ├── halted
rst_n ──┤       CPU 4-bit core     │
        └──────────────────────────┘
                       ▲
                       │
                imem_rdata[7:0]
                     SOUTH
```

Trong file pin placement:

- `#N`: cạnh Bắc.
- `#S`: cạnh Nam.
- `#E`: cạnh Đông.
- `#W`: cạnh Tây.
- Dấu `[` và `]` phải được escape vì mỗi dòng được hiểu là regular expression.

OpenLane vẫn chọn tọa độ hợp lệ trên routing grid, nhưng cạnh và thứ tự pin là quyết định của người thiết kế.

## 6. Khởi động môi trường OpenLane

OpenLane 2 được cài tại `~/EDA/openlane2`. Mở terminal mới:

```bash
cd ~/EDA/openlane2
nix-shell
```

Lần đầu vào Nix shell có thể mất thời gian để tải tool hoặc PDK. Trong Nix shell, kiểm tra cài đặt:

```bash
openlane --version
openlane --smoke-test
```

Sau đó chuyển sang project nhưng vẫn ở trong Nix shell:

```bash
cd ~/Workspaces/cpu_4bit
```

## 7. Nguyên tắc chạy từng giai đoạn

Tutorial sử dụng một run tag cố định:

```text
manual_pd_01
```

Lần đầu, OpenLane tạo:

```text
runs/manual_pd_01/
```

Các lần sau dùng lại cùng `--run-tag manual_pd_01`. OpenLane sẽ load `state_out.json` mới nhất và tiếp tục trong cùng run.

Không thêm `--overwrite` khi đang tiếp tục, vì tùy chọn đó xóa nội dung run hiện có. Nếu muốn làm lại từ đầu, dùng tag mới như `manual_pd_02`.

## 8. Giai đoạn 1 — lint và synthesis

```bash
openlane --run-tag manual_pd_01 \
  --to Yosys.Synthesis \
  config.json
```

Nhóm này thực hiện:

```text
RTL lint
→ timing-construct checks
→ RTL elaboration
→ technology mapping
→ gate-level netlist
```

Kiểm tra sau synthesis:

- Top module là `cpu_4bit`.
- Không có `tb.sv`, `program_rom.sv` hoặc `program.hex` trong synthesis.
- Không có latch ngoài ý muốn.
- Không có unmapped logic quan trọng.
- Netlist chứa standard cells của `sky130_fd_sc_hd`.
- Xem số lượng cells và tổng cell area.

Liệt kê output:

```bash
find runs/manual_pd_01 -maxdepth 2 -type f | sort
```

## 9. Giai đoạn 2 — kiểm tra netlist và floorplan

```bash
openlane --run-tag manual_pd_01 \
  --from Checker.YosysUnmappedCells \
  --to OpenROAD.Floorplan \
  config.json
```

Nhóm này thực hiện:

```text
post-synthesis checks
→ SDC checks
→ pre-PnR STA
→ die/core floorplan
→ standard-cell rows
```

Kiểm tra:

- Die area và core area.
- Core utilization.
- Standard-cell rows.
- Khoảng trống dành cho routing.
- Timing trước placement.

Ở lần chạy đầu, OpenLane tự tính die/core size dựa trên cell area và `FP_CORE_UTIL`. Không nên đoán `DIE_AREA` trước khi biết synthesis area.

## 10. Tùy chọn: cố định die area sau lần floorplan đầu

Sau khi đọc báo cáo area, có thể chuyển sang floorplan tuyệt đối:

```json
"FP_SIZING": "absolute",
"DIE_AREA": [0, 0, 100, 100]
```

`DIE_AREA` có dạng `[x0, y0, x1, y1]`, đơn vị µm. Giá trị `100 × 100 µm` chỉ là ví dụ, không phải giá trị đã được tối ưu cho CPU này.

Nếu thay đổi `config.json`, nên tạo run mới:

```text
manual_pd_02
```

Điều này giúp so sánh auto-sized floorplan với fixed-size floorplan mà không trộn state của hai cấu hình.

## 11. Giai đoạn 3 — PDN và placement

```bash
openlane --run-tag manual_pd_01 \
  --from Odb.CheckMacroAntennaProperties \
  --to OpenROAD.DetailedPlacement \
  config.json
```

Nhóm này thực hiện:

```text
power connections
→ tap/endcap insertion
→ power distribution network
→ global placement
→ custom I/O placement
→ placement optimization
→ detailed placement/legalization
```

Kiểm tra:

- `clk`/`rst_n` ở cạnh Tây, `halted` ở cạnh Đông.
- `imem_addr` ở cạnh Bắc, `imem_rdata` ở cạnh Nam.
- Standard cells không overlap.
- Không có placement legality error.
- PDN phủ core hợp lý.
- Không có vùng congestion quá lớn.

## 12. Giai đoạn 4 — CTS và global routing

```bash
openlane --run-tag manual_pd_01 \
  --from OpenROAD.CTS \
  --to OpenROAD.GlobalRouting \
  config.json
```

Nhóm này thực hiện:

```text
clock-tree synthesis
→ post-CTS timing optimization
→ global routing
```

Kiểm tra:

- Clock buffers đã được chèn.
- Clock skew và insertion delay.
- Setup/hold timing sau CTS.
- Global-routing congestion.
- Routing layers được sử dụng.

## 13. Giai đoạn 5 — antenna repair và detailed routing

```bash
openlane --run-tag manual_pd_01 \
  --from OpenROAD.CheckAntennas \
  --to OpenROAD.DetailedRouting \
  config.json
```

Nhóm này thực hiện:

```text
antenna checking/repair
→ post-global-routing optimization
→ detailed routing
```

Kiểm tra:

- Detailed-routing DRC.
- Antenna violations.
- Unconnected pins.
- Wire length.
- Timing sau routing.

## 14. Giai đoạn 6 — extraction và signoff

```bash
openlane --run-tag manual_pd_01 \
  --from Odb.RemoveRoutingObstructions \
  config.json
```

Không có `--to`, nên OpenLane chạy đến cuối Classic flow:

```text
routing checks
→ filler insertion
→ RC extraction
→ post-PnR STA
→ GDS stream-out
→ DRC
→ LVS
→ final timing checks
→ manufacturability report
```

Điều kiện kết thúc mong đợi:

- Không có flow error.
- DRC clean hoặc hiểu rõ mọi violation còn lại.
- LVS pass.
- Không có setup/hold violation ở corner được kiểm tra.
- Có GDS, DEF, netlist và timing reports cuối.

## 15. Kết quả cuối

Các view cuối nằm tại:

```text
runs/manual_pd_01/final/
```

Liệt kê chúng:

```bash
find runs/manual_pd_01/final -type f | sort
```

Các output quan trọng:

- GDSII: layout dùng cho fabrication/signoff.
- DEF/ODB: database placement và routing.
- Gate-level Verilog: netlist sau implementation.
- SDC: timing constraints.
- SPEF: parasitic RC sau routing.
- Reports: area, timing, DRC, LVS và manufacturability.

## 16. Mở layout để quan sát

Mở state mới nhất bằng OpenROAD GUI:

```bash
openlane --last-run \
  --flow OpenInOpenROAD \
  config.json
```

Mở layout cuối bằng KLayout:

```bash
openlane --last-run \
  --flow OpenInKLayout \
  config.json
```

`--last-run` chọn run được cập nhật gần nhất. Nếu có nhiều run, kiểm tra thư mục `runs/` trước để tránh mở nhầm.

## 17. Chạy toàn bộ flow tự động để đối chiếu

Sau khi đã hiểu từng giai đoạn, có thể chạy một run riêng từ đầu đến cuối:

```bash
openlane --run-tag automatic_pd_01 config.json
```

So sánh `manual_pd_01` và `automatic_pd_01`:

- Final cell count.
- Die/core area.
- Worst setup slack.
- Worst hold slack.
- Clock skew.
- Total wire length.
- DRC/LVS status.

Nếu hai run dùng cùng cấu hình và không có thay đổi tương tác, kết quả dự kiến tương đương. Giá trị của việc chia step là khả năng dừng lại để đọc report và hiểu state tại từng mốc.

## 18. Xử lý lỗi

Tìm error và warning trong run:

```bash
find runs/manual_pd_01 -type f \
  \( -name '*error*' -o -name '*warning*' -o -name '*.log' \) \
  | sort
```

Tìm nhanh các dòng quan trọng:

```bash
rg -n "ERROR|FATAL|violation|unmapped|failed" runs/manual_pd_01
```

Khi một step lỗi:

1. Đọc log trong thư mục step vừa chạy.
2. Xác định lỗi thuộc RTL, constraint, floorplan, placement, routing hay signoff.
3. Nếu sửa RTL hoặc `config.json`, dùng run tag mới.
4. Nếu chỉ điều tra output, giữ nguyên run hiện tại.

Không bỏ qua DRC/LVS hoặc timing failure chỉ để tạo được GDS.

## 19. Checklist cho seminar

- [ ] RTL simulation pass với `ACC = 6`.
- [ ] CPU không chứa program ROM cố định.
- [ ] Synthesis không đọc testbench hay `program.hex`.
- [ ] Pin placement khớp kiến trúc memory interface.
- [ ] Floorplan và utilization được giải thích.
- [ ] Placement legal.
- [ ] CTS hoàn tất và clock timing được phân tích.
- [ ] Global/detailed routing hoàn tất.
- [ ] DRC và LVS được kiểm tra.
- [ ] Setup/hold timing được báo cáo.
- [ ] Final GDS được mở và chụp cho slide seminar.
- [ ] Area, cell count, frequency target và kết quả timing được tổng hợp thành bảng.

## 20. Lệnh tóm tắt

```bash
cd ~/EDA/openlane2
nix-shell
cd ~/Workspaces/cpu_4bit
```

```bash
openlane --run-tag manual_pd_01 --to Yosys.Synthesis config.json
```

```bash
openlane --run-tag manual_pd_01 \
  --from Checker.YosysUnmappedCells \
  --to OpenROAD.Floorplan \
  config.json
```

```bash
openlane --run-tag manual_pd_01 \
  --from Odb.CheckMacroAntennaProperties \
  --to OpenROAD.DetailedPlacement \
  config.json
```

```bash
openlane --run-tag manual_pd_01 \
  --from OpenROAD.CTS \
  --to OpenROAD.GlobalRouting \
  config.json
```

```bash
openlane --run-tag manual_pd_01 \
  --from OpenROAD.CheckAntennas \
  --to OpenROAD.DetailedRouting \
  config.json
```

```bash
openlane --run-tag manual_pd_01 \
  --from Odb.RemoveRoutingObstructions \
  config.json
```
