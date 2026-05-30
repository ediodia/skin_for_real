const { setGlobalOptions } = require('firebase-functions');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const fetch = require('node-fetch');

setGlobalOptions({ maxInstances: 10 });

const AZURE_KEY = defineSecret('AZURE_KEY');
const GROQ_KEY = defineSecret('GROQ_KEY');

exports.analyzeface = onRequest(
  { secrets: [AZURE_KEY] },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const body = req.rawBody || req.body;
      const response = await fetch(
        'https://skinforreal-face-api.cognitiveservices.azure.com/face/v1.0/detect?returnFaceAttributes=blur,exposure,noise,occlusion,glasses,headPose',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/octet-stream',
            'Ocp-Apim-Subscription-Key': AZURE_KEY.value(),
          },
          body: body,
        }
      );
      const data = await response.json();
      res.json(data);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  }
);

exports.groqchat = onRequest(
  { secrets: [GROQ_KEY] },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${GROQ_KEY.value()}`,
        },
        body: JSON.stringify(req.body),
      });
      const data = await response.json();
      res.json(data);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  }
);