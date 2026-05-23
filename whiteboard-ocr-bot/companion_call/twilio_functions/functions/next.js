// Public endpoint: POST /next?start=TS&recent=2,5
// After mom finishes talking. Picks next rotation prompt or switches to closer.
// State is read from URL query params (start timestamp + recent picks list).
exports.handler = function (context, event, callback) {
  const twiml = new Twilio.twiml.VoiceResponse();
  const domain = context.DOMAIN_NAME;

  const startTs = parseInt(event.start || '0', 10);
  const elapsed = (Date.now() - startTs) / 1000;
  const endTrigger = parseInt(context.END_TRIGGER_SEC || '80', 10);

  // Switch to closer (prompt_11) once accumulated time exceeds threshold
  if (elapsed >= endTrigger) {
    twiml.play(`https://${domain}/prompt_11.wav`);
    twiml.hangup();
    return callback(null, twiml);
  }

  // Rotation pool: prompt_02..10 + 12
  const middle = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12];
  const recentParam = (event.recent || '').toString();
  const recent = recentParam.split(',').filter((x) => x).map(Number);

  let candidates = middle.filter((i) => !recent.includes(i));
  if (candidates.length === 0) candidates = middle;
  const pick = candidates[Math.floor(Math.random() * candidates.length)];

  // Keep last 2 picks to avoid repeats (rolling window)
  const newRecent = [...recent.slice(-1), pick].join(',');
  const fname = 'prompt_' + pick.toString().padStart(2, '0') + '.wav';

  twiml.play(`https://${domain}/${fname}`);
  twiml.pause({ length: 3 });
  twiml.redirect(
    { method: 'POST' },
    `https://${domain}/next?start=${startTs}&recent=${newRecent}`
  );

  callback(null, twiml);
};
