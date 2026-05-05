// Public endpoint: POST /voice
// Triggered when mom answers. Plays opener (prompt_01) then redirects to /next.
// State is passed via URL params to /next (Functions are stateless).
exports.handler = function (context, event, callback) {
  const twiml = new Twilio.twiml.VoiceResponse();
  const startTs = Date.now();

  twiml.play(`https://${context.DOMAIN_NAME}/prompt_01.wav`);
  twiml.pause({ length: 3 });
  twiml.redirect(
    { method: 'POST' },
    `https://${context.DOMAIN_NAME}/next?start=${startTs}&recent=`
  );

  callback(null, twiml);
};
