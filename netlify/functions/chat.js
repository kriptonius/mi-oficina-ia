// Netlify Function: secure server-side proxy for OpenAI Responses API.
// Configure OPENAI_API_KEY in Netlify environment variables. Never put it in frontend code.
exports.handler = async (event) => {
  const origin = process.env.ALLOWED_ORIGIN || '*';
  const headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin'
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers, body: '' };
  }
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: JSON.stringify({ error: 'Method not allowed' }) };
  }
  if (!process.env.OPENAI_API_KEY) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: 'Server is missing OPENAI_API_KEY configuration.' }) };
  }

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Invalid JSON body.' }) };
  }

  const message = typeof payload.message === 'string' ? payload.message.trim() : '';
  if (!message) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'A non-empty message is required.' }) };
  }
  if (message.length > 12000) {
    return { statusCode: 413, headers, body: JSON.stringify({ error: 'Message is too long.' }) };
  }

  const agent = typeof payload.agent === 'string' ? payload.agent.slice(0, 80) : 'EL ARQUI';
  const instructions = typeof payload.instructions === 'string' ? payload.instructions.slice(0, 6000) : '';
  const input = [
    'Eres el agente ' + agent + ' de Mi Oficina IA.',
    'Responde en español, con claridad y pasos prácticos.',
    'No afirmes haber realizado acciones externas si no las has ejecutado.',
    instructions ? 'Instrucciones del agente: ' + instructions : ''
  ].filter(Boolean).join('\n\n') + '\n\nSolicitud del usuario:\n' + message;

  try {
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + process.env.OPENAI_API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
        input,
        max_output_tokens: 1200
      })
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      console.error('OpenAI API request failed with status', response.status);
      return {
        statusCode: 502,
        headers,
        body: JSON.stringify({ error: 'The AI provider request failed.', status: response.status })
      };
    }

    const answer = Array.isArray(data.output)
      ? data.output.flatMap(item => Array.isArray(item.content) ? item.content : [])
          .filter(item => item.type === 'output_text')
          .map(item => item.text || '')
          .join('\n')
      : '';

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ answer: answer || 'No se recibió texto de respuesta.' })
    };
  } catch (error) {
    console.error('AI proxy error:', error && error.message ? error.message : 'unknown');
    return { statusCode: 502, headers, body: JSON.stringify({ error: 'Could not reach the AI provider.' }) };
  }
};
