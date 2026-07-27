import 'package:flutter/material.dart';

/// About / privacy / medical-disclaimer screen.
///
/// The trust core of the app: it states plainly that everything runs on-device
/// and that this is a record-keeping tool, not a medical device. Wording is
/// written to match the app's real behaviour (zero cloud, local-only, offline
/// recognition, user-initiated sharing).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('關於與隱私')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _Title('照護紀錄'),
            _Body(
              '用「講的」記錄每天的照護狀況，回診時整理給醫療人員參考。'
              '語音辨識與標點都在你手機本機完成，資料只存在這支手機裡。',
            ),
            SizedBox(height: 24),
            _Heading('🔒 隱私（你的資料只屬於你）'),
            _Bullet('這個 App 完全在你手機上運作。你的紀錄、照片、語音，都只存在這支手機裡。'),
            _Bullet('開發者看不到、也拿不到你的任何資料。App 不會把你的資料上傳到任何伺服器。'),
            _Bullet('語音辨識與標點是在手機本機（離線）完成的，不會把你的錄音送到雲端。'),
            _Bullet('首次啟動時會從網路下載一次語音模型檔，之後即可完全離線使用。'),
            _Bullet('沒有帳號、不需註冊、不收集個人資料、沒有廣告、沒有追蹤。'),
            _Bullet(
              '當你主動「匯出」或「分享」資料（例如用 LINE 傳送 ZIP 或 HTML 檔）時，'
              '那是你自己選擇送出的動作——一旦送出，該傳送管道（例如 LINE）可能看得到內容，請自行斟酌。',
            ),
            _Bullet('你可以隨時在 App 裡刪除紀錄；移除整個 App 即可清除這支手機上的所有資料。'),
            SizedBox(height: 24),
            _Heading('🩺 醫療免責聲明'),
            _Bullet('本 App 是「照護紀錄」工具，協助你記錄與整理日常照護觀察，方便回診時提供給醫療人員參考。'),
            _Bullet('本 App 不是醫療器材，不提供醫療診斷、治療或建議。'),
            _Bullet(
              '語音辨識可能有錯字或遺漏，請務必自行核對後再使用；'
              '請勿僅依賴辨識出的文字做任何醫療判斷。',
            ),
            _Bullet('任何健康、用藥或照護決定，請諮詢合格的醫療專業人員。'),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
      );
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C5D80))),
      );
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 20, height: 1.7, color: Color(0xFF222222)));
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('・',
                style: TextStyle(fontSize: 20, height: 1.7, color: Color(0xFF222222))),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 20, height: 1.7, color: Color(0xFF222222))),
            ),
          ],
        ),
      );
}
