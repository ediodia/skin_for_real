const { onRequest } = require('firebase-functions/v2/https');
const functionsV1 = require('firebase-functions/v1');
const https = require('https');

exports.claudeProxy = onRequest({
  cors: true,
  secrets: ['GROQ_KEY'],
}, (req, res) => {
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).send('Method not allowed');
    return;
  }

  const apiKey = process.env.GROQ_KEY;

  if (!apiKey) {
    console.error('GROQ_KEY secret not found');
    res.status(500).json({ error: 'API key not configured' });
    return;
  }

  const body = JSON.stringify({
    model: 'llama-3.3-70b-versatile',
    max_tokens: 1000,
    messages: req.body.messages,
  });

  const options = {
    hostname: 'api.groq.com',
    path: '/openai/v1/chat/completions',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
      'Content-Length': Buffer.byteLength(body),
    },
  };

  const proxyReq = https.request(options, (proxyRes) => {
    let data = '';
    proxyRes.on('data', chunk => data += chunk);
    proxyRes.on('end', () => {
      console.log('Groq response status:', proxyRes.statusCode);
      try {
        const groqData = JSON.parse(data);
        const claudeFormat = {
          content: [{
            type: 'text',
            text: groqData.choices[0].message.content
          }]
        };
        res.status(proxyRes.statusCode).json(claudeFormat);
      } catch (e) {
        res.status(500).json({ error: 'Parse error', raw: data });
      }
    });
  });

  proxyReq.on('error', (e) => {
    console.error('Proxy error:', e);
    res.status(500).json({ error: e.message });
  });

  proxyReq.write(body);
  proxyReq.end();
});

exports.sendWelcomeEmail = functionsV1
  .runWith({ secrets: ['RESEND_KEY'] })
  .auth.user()
  .onCreate(async (user) => {
    const apiKey = process.env.RESEND_KEY;
    if (!apiKey) {
      console.error('RESEND_KEY not set');
      return;
    }

    const firstName = user.displayName?.split(' ')[0] || 'there';
    const email = user.email;
    if (!email) return;

    const html = `
      <div style="font-family: -apple-system, sans-serif; background: #0a0a1a; padding: 40px; border-radius: 16px; color: #ffffff;">
        <h1 style="background: linear-gradient(135deg, #B76EF5, #6EE4F5, #F56EB7); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-size: 32px; font-weight: 800; margin: 0 0 12px;">
          Welcome to SkinForReal ✨
        </h1>
        <p style="font-size: 16px; color: #cccccc; line-height: 1.6;">
          Hey ${firstName} 👋
        </p>
        <p style="font-size: 15px; color: #aaaaaa; line-height: 1.7;">
          Your skin journey just got smarter. We use AI-powered analysis to understand your skin type, track your progress over time, and build a routine that actually works for you.
        </p>
        <div style="margin: 28px 0; padding: 20px; background: rgba(123,47,190,0.1); border: 1px solid rgba(123,47,190,0.3); border-radius: 12px;">
          <p style="margin: 0; font-size: 14px; color: #B76EF5; font-weight: 700;">Quick tip:</p>
          <p style="margin: 8px 0 0; font-size: 14px; color: #cccccc;">
            Try the face analyzer for a deeper look at your skin — it's the fastest way to get personalized recommendations.
          </p>
        </div>
        <p style="font-size: 13px; color: #666666;">
          See you in the app 🧬
        </p>
      </div>
    `;

    const body = JSON.stringify({
      from: 'SkinForReal <onboarding@resend.dev>',
      to: [email],
      subject: 'Welcome to SkinForReal ✨',
      html: html,
    });

    const options = {
      hostname: 'api.resend.com',
      path: '/emails',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
        'Content-Length': Buffer.byteLength(body),
      },
    };

    return new Promise((resolve, reject) => {
      const req = https.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          console.log('Resend response:', res.statusCode, data);
          resolve();
        });
      });
      req.on('error', (e) => {
        console.error('Resend error:', e);
        reject(e);
      });
      req.write(body);
      req.end();
    });
  });
