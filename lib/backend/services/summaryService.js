const supabase = require('../config/database');
const { getEmailById } = require('./emailService');
const { llm } = require('../config/env');

const MAX_CONTENT_CHARS = 2000;
const NO_CONTENT_MESSAGE = 'Email has no content to summarize';
const LLM_TIMEOUT_MS = 20_000;

const NAMED_ENTITIES = {
  nbsp: ' ', amp: '&', lt: '<', gt: '>', quot: '"', apos: "'",
  mdash: '\u2014', ndash: '\u2013', hellip: '...',
};

function decodeEntities(text) {
  return text
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(Number(dec)))
    .replace(/&([a-z]+);/gi, (match, name) => NAMED_ENTITIES[name.toLowerCase()] ?? match);
}

function stripHtml(html) {
  const text = html
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ');
  return decodeEntities(text).replace(/\s+/g, ' ').trim();
}

function scrubPersonalData(text) {
  return text
    .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g, '')
    .replace(/https?:\/\/\S+/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function emailContent(email) {
  if (email.body_text?.trim()) return scrubPersonalData(email.body_text);
  if (email.body_html?.trim()) return scrubPersonalData(stripHtml(email.body_html));
  return scrubPersonalData(email.snippet || '');
}

function buildPrompt(subject, content) {
  return [
    'Summarize this email in 3-4 very short single-line bullet points.',
    'Focus only on the main content and key points.',
    'Do not include sender names, email addresses, or any personal information.',
    '',
    `Subject: ${subject}`,
    'Content:',
    content.slice(0, MAX_CONTENT_CHARS),
  ].join('\n');
}

async function requestSummary(subject, content) {
  const response = await fetch(`${llm.baseUrl}/chat/completions`, {
    method: 'POST',
    signal: AbortSignal.timeout(LLM_TIMEOUT_MS),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${llm.apiKey}`,
    },
    body: JSON.stringify({
      model: llm.model,
      temperature: 0.2,
      max_tokens: 200,
      messages: [{ role: 'user', content: buildPrompt(subject, content) }],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`LLM request failed (${response.status}): ${body.slice(0, 200)}`);
  }

  const data = await response.json();
  const summary = data.choices?.[0]?.message?.content?.trim();
  if (!summary) {
    throw new Error('LLM returned an empty summary');
  }
  return summary;
}

async function summarizeEmail(userId, emailId) {
  const email = await getEmailById(userId, emailId);
  if (email.summary) {
    return email.summary;
  }

  const content = emailContent(email);
  if (!content) {
    throw new Error(NO_CONTENT_MESSAGE);
  }

  const summary = await requestSummary(email.subject || '', content);

  const { error } = await supabase
    .from('emails')
    .update({ summary })
    .eq('id', email.id);
  if (error) {
    console.error('Failed to cache summary:', error.message);
  }

  return summary;
}

module.exports = { summarizeEmail, stripHtml, buildPrompt, emailContent, NO_CONTENT_MESSAGE };
