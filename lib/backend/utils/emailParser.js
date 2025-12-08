function decodeBase64Url(data) {
  let buffer = data.replace(/-/g, '+').replace(/_/g, '/');
  while (buffer.length % 4) {
    buffer += '=';
  }
  return Buffer.from(buffer, 'base64');
}

async function parseEmailBody(payload) {
  let bodyText = '';
  let bodyHtml = '';

  const processPart = async (part) => {
    if (part.mimeType === 'text/plain' && part.body && part.body.data) {
      bodyText = decodeBase64Url(part.body.data).toString('utf-8');
    } else if (part.mimeType === 'text/html' && part.body && part.body.data) {
      bodyHtml = decodeBase64Url(part.body.data).toString('utf-8');
    }

    if (part.parts) {
      for (const nestedPart of part.parts) {
        await processPart(nestedPart);
      }
    }
  };

  await processPart(payload);
  return { bodyText, bodyHtml };
}

function extractAttachments(payload) {
  const attachments = [];
  const processPart = (part) => {
    if (part.filename && part.body && part.body.attachmentId) {
      const contentIdHeader = part.headers?.find(h => h.name?.toLowerCase() === 'content-id');
      const contentId = contentIdHeader ? contentIdHeader.value?.replace(/<|>/g, '') : null;

      attachments.push({
        filename: part.filename,
        mimeType: part.mimeType,
        attachmentId: part.body.attachmentId,
        size: part.body.size,
        contentId: contentId,
      });
    }
    if (part.parts) {
      for (const nestedPart of part.parts) {
        processPart(nestedPart);
      }
    }
  };
  processPart(payload);
  return attachments;
}

async function extractEmailHeaders(headers) {
  const result = {
    subject: '',
    from: '',
    fromName: '',
    to: '',
    cc: '',
    bcc: '',
    date: new Date(),
  };

  for (const header of headers || []) {
    const name = header.name?.toLowerCase();
    const value = header.value || '';

    switch (name) {
      case 'subject':
        result.subject = value;
        break;
      case 'from':
        result.from = value;
        const fromMatch = value.match(/^(.+?)\s*<(.+?)>$|^(.+?)$/);
        if (fromMatch) {
          result.fromName = fromMatch[1]?.trim() || fromMatch[3]?.trim() || '';
          result.from = fromMatch[2]?.trim() || fromMatch[3]?.trim() || value;
        }
        break;
      case 'to':
        result.to = value;
        break;
      case 'cc':
        result.cc = value;
        break;
      case 'bcc':
        result.bcc = value;
        break;
      case 'date':
        result.date = new Date(value);
        break;
    }
  }

  return result;
}

module.exports = {
  parseEmailBody,
  extractAttachments,
  extractEmailHeaders,
  decodeBase64Url,
};

