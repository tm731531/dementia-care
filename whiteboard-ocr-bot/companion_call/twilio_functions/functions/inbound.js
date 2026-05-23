// Public endpoint: POST /inbound
// Handles inbound calls (mom calling back the Twilio number).
// Polite hangup to avoid voicemail charges and confusion.
exports.handler = function (context, event, callback) {
  const twiml = new Twilio.twiml.VoiceResponse();
  twiml.say(
    { language: 'zh-TW', voice: 'Polly.Hui' },
    '我先去忙，先這樣喔。'
  );
  twiml.hangup();
  callback(null, twiml);
};
