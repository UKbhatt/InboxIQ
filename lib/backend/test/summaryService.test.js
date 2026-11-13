const test = require('node:test');
const assert = require('node:assert/strict');

process.env.ENCRYPTION_KEY = 'a'.repeat(64);
process.env.SUPABASE_URL = 'https://example.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-role-key';
const { stripHtml, emailContent, buildPrompt } = require('../services/summaryService');

test('stripHtml drops tags, scripts and styles and decodes common entities', () => {
  const html = '<style>p{}</style><p>Hello&nbsp;<b>world</b> &amp; friends</p><script>x()</script>';
  assert.equal(stripHtml(html), 'Hello world & friends');
});

test('emailContent prefers plain text, then stripped html, then snippet', () => {
  assert.equal(emailContent({ body_text: 'plain', body_html: '<p>html</p>', snippet: 'snip' }), 'plain');
  assert.equal(emailContent({ body_text: '  ', body_html: '<p>html</p>', snippet: 'snip' }), 'html');
  assert.equal(emailContent({ body_text: null, body_html: null, snippet: 'snip' }), 'snip');
  assert.equal(emailContent({}), '');
});

test('buildPrompt truncates long content to the configured limit', () => {
  const prompt = buildPrompt('Subject', 'x'.repeat(5000));
  assert.ok(prompt.includes('Subject: Subject'));
  assert.ok(prompt.length < 2500);
});

test('emailContent strips email addresses and links before the prompt is built', () => {
  const content = emailContent({
    body_text: 'Hi alice@corp.com, reset here: https://x.com/reset?token=abc123 today',
  });
  assert.equal(content, 'Hi , reset here: today');
});

test('stripHtml decodes named and numeric entities', () => {
  assert.equal(stripHtml('Sale ends tonight &mdash; don&#8217;t miss it'), 'Sale ends tonight — don’t miss it');
});
