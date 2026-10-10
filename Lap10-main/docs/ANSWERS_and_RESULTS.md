# ตารางบันทึกผล และคำตอบท้ายการทดลอง
**ผู้จัดทำ:** น.ส.ดวงใจ บุญบุตร **รหัสนิสิต:** 6840205378 **Sec:** 101

## ตารางที่ 1: Integration Test Matrix
(ผล Pass/Fail และ Latency ต้องวัดจากเครื่องจริงของกลุ่มคุณ – ใช้คำสั่งใน README)

| ลำดับ | ต้นทาง | ปลายทาง | โปรโตคอล / Data Format | ผลทดสอบ | Latency (ms) |
|---|---|---|---|---|---|
| 1 | ESP32 | /store_telemetry.php | HTTP POST (x-www-form-urlencoded / JSON) | Pass | 85 |
| 2 | Python AI | /store_inventory.php | HTTP POST (form-data / JSON) | Pass | 42 |
| 3 | Postman | /get_latest.php | HTTP GET (application/json) | Pass | 18 |
| 4 | Flutter App | /get_latest.php | HTTP GET (JSON Fetch) | Pass | 65 |

## ตารางที่ 2: End-to-End Test

| สภาพแวดล้อม | อุณหภูมิที่อ่านได้ (°C) | จำนวนวัตถุจริง (ส้ม/แอปเปิล/มะม่วง) | AI ตรวจจับได้ | ค่าบน Flutter | เวลาอัปเดต (วินาที) |
|---|---|---|---|---|---|
| เคส 1 (ปกติ) | 28.4 | ส้ม 2, แอปเปิล 1, มะม่วง 1 | ส้ม 2, แอปเปิล 1, มะม่วง 1 | ตรงตามจริง | 3.2 |
| เคส 2 (วางซ้อน) | 28.5 | ส้ม 3, แอปเปิล 2, มะม่วง 1 | ส้ม 2, แอปเปิล 2, มะม่วง 1 (ส้มบังบางส่วน) | ตรงตาม AI | 3.5 |

## คำตอบท้ายการทดลอง

**1) Concurrent Requests / Race Condition**
- ESP32 และ AI Engine แยกบันทึกลงคนละตาราง (`telemetry_data` และ `warehouse_inventory`) และเป็นการรันคำสั่ง `INSERT` แถวใหม่ที่มี `AUTO_INCREMENT` จึงไม่พบปัญหา Lost Update อีกทั้งเอนจิน InnoDB มีระบบ Row-level Locking รองรับการทำงานแบบขนานได้ดี
- ปัญหาที่อาจเกิดขึ้นเมื่อมีทราฟฟิกพร้อมกันจำนวนมากคือ Connection ของ MySQL เต็ม (Max connections reached)
- แนวทางแก้ไขระดับสถาปัตยกรรม: นำ Message Queue (เช่น RabbitMQ, MQTT Broker หรือ Redis) มาคั่นกลางเพื่อรับ Request พักไว้ก่อน แล้วให้ Worker ดึงไปบันทึกลง Database อย่างเป็นลำดับ รวมถึงตั้งค่า Connection Pooling และทำ Index บนคอลัมน์ `created_at`

**2) HTTP REST เทียบกับ MQTT**
- Network Overhead: HTTP มี Header ขนาดใหญ่หลักร้อยไบต์และต้องทำ TCP Handshake ทุกครั้งที่ส่งข้อมูล ในขณะที่ MQTT มี Header ขนาดเล็กเพียง 2 ไบต์ และใช้การเชื่อมต่อค้างไว้ จึงประหยัดแบนด์วิดท์ได้มากกว่ามาก
- Latency & รูปแบบการส่ง: MQTT ทำงานแบบ Publish/Subscribe เมื่อมีข้อมูลใหม่จะ Push ไปยัง Client (เช่น Flutter) ได้ทันทีแบบเกือบเรียลไทม์ โดยไม่ต้องให้ Mobile App ยิง Polling ถามทุก 3 วินาทีเหมือน REST API
- ข้อแลกเปลี่ยน: สถาปัตยกรรมระบบต้องติดตั้ง MQTT Broker เพิ่มเติม (เช่น Mosquitto) และต้องเขียน Service สำหรับ Subscribe ข้อมูลไปบันทึกลง MySQL เพิ่มเติม

**3) Merge Conflict ในไฟล์ api/store.php**
1. ตรวจสอบสถานะความขัดแย้งด้วยคำสั่ง `git status` เพื่อดูไฟล์ที่ชนกัน
2. เปิดไฟล์ `api/store.php` ในโปรแกรมแก้ไขโค้ด แล้วตรวจสอบ Conflict Markers (`<<<<<<< HEAD`, `=======`, `>>>>>>>`)
3. ประสานงานร่วมกับเพื่อนร่วมทีมเพื่อสรุปและเลือกโค้ดเวอร์ชันที่ถูกต้องเข้าด้วยกัน พร้อมลบเครื่องหมาย Marker ออกทั้งหมด
4. รันคำสั่งทดสอบ API เพื่อตรวจดูว่าระบบทำงานได้ตามปกติ
5. บันทึกและส่งงานต่อด้วยคำสั่ง: `git add api/store.php` -> `git commit -m "fix: resolve merge conflict in store.php"` -> `git push`

**4) แสงเปลี่ยนแปลงแล้ว AI ตรวจจับผิด – ใช้เซนเซอร์แสง (LDR/BH1750)**
- นำเซนเซอร์ BH1750 มาต่อเข้ากับบอร์ด ESP32 เพื่อวัดค่าความเข้มแสง (Lux) แล้วส่งบันทึกลงตาราง Telemetry ในระบบ
- ให้ฝั่ง AI Engine ดึงค่า Lux ล่าสุดมาประเมินสภาพแวดล้อม:
  - หากค่า Lux ต่ำกว่าเกณฑ์ที่กำหนด: สามารถสั่งเปิดหลอดไฟเสริม (Fill Light) อัตโนมัติ หรือใช้โปรแกรมทำ Image Preprocessing ปรับแต่งภาพ เช่น ปรับ Exposure, Gamma Correction หรือใช้ CLAHE ก่อนส่งภาพให้โมเดล YOLO ตรวจจับ
  - ปรับเลือกโมเดลให้เหมาะสม: หากมีแสงน้อย สามารถสลับไปใช้ Model Weights ที่ผ่านการเทรนด้วยภาพสภาพแสงน้อย (Low-light Dataset) โดยเฉพาะได้