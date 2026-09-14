import { aiAnalysisSchema, type AIAnalysisOutput } from './validators';

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1';

export interface ModelInfo {
  id: string;
  name: string;
  context_length?: number;
  pricing?: {
    prompt: string;
    completion: string;
  };
  provider?: string;
}

export async function getOpenRouterModels(): Promise<ModelInfo[]> {
  try {
    const response = await fetch(`${OPENROUTER_BASE_URL}/models`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
      },
    });

    if (!response.ok) {
      console.error('Failed to fetch models:', response.status);
      return [];
    }

    const data = await response.json();
    return data.data || [];
  } catch (error) {
    console.error('Error fetching OpenRouter models:', error);
    return [];
  }
}

export async function analyzeWithAI(
  model: string,
  sensorData: {
    soilMoisture: number;
    temperature: number;
    humidity: number;
    waterLevel: number;
    flowRate: number;
    lightLevel: number;
    pumpStatus: boolean;
    deviceStatus: string;
  },
  cropProfile: {
    name: string;
    minimumMoisture: number;
    targetMoisture: number;
    maximumMoisture: number;
    minTemperature: number;
    maxTemperature: number;
  },
  historicalData: Array<{
    timestamp: Date;
    soilMoisture: number;
    temperature: number;
    humidity: number;
  }>,
  temperature: number = 0.2,
  maxTokens: number = 1200
): Promise<AIAnalysisOutput | null> {
  if (!OPENROUTER_API_KEY) {
    console.error('OpenRouter API key not configured');
    return null;
  }

  const trendDescription = historicalData.length > 1 
    ? `Over the past ${historicalData.length} readings, soil moisture has ${
        historicalData[historicalData.length - 1].soilMoisture > historicalData[0].soilMoisture 
          ? 'increased' 
          : historicalData[historicalData.length - 1].soilMoisture < historicalData[0].soilMoisture 
            ? 'decreased' 
            : 'remained stable'
      } from ${historicalData[0].soilMoisture}% to ${historicalData[historicalData.length - 1].soilMoisture}%.`
    : 'Insufficient historical data for trend analysis.';

  const prompt = `You are an agricultural AI assistant analyzing crop health based on sensor data.

CROP PROFILE:
- Crop: ${cropProfile.name}
- Target soil moisture: ${cropProfile.targetMoisture}%
- Minimum soil moisture: ${cropProfile.minimumMoisture}%
- Maximum soil moisture: ${cropProfile.maximumMoisture}%
- Optimal temperature range: ${cropProfile.minTemperature}°C - ${cropProfile.maxTemperature}°C

CURRENT SENSOR READINGS:
- Soil Moisture: ${sensorData.soilMoisture}%
- Temperature: ${sensorData.temperature}°C
- Humidity: ${sensorData.humidity}%
- Water Tank Level: ${sensorData.waterLevel}%
- Flow Rate: ${sensorData.flowRate} L/min
- Light Level: ${sensorData.lightLevel}%
- Pump Status: ${sensorData.pumpStatus ? 'ON' : 'OFF'}
- Device Status: ${sensorData.deviceStatus}

HISTORICAL TREND:
${trendDescription}

Analyze the crop health and provide recommendations. Be conservative in your assessments - only flag issues when there is clear evidence from the sensor data. Do not diagnose specific diseases that cannot be determined from sensor readings alone.

Return your analysis as a JSON object with this exact structure:
{
  "healthScore": number (0-100),
  "healthStatus": "healthy" | "stressed" | "critical",
  "waterStress": "low" | "medium" | "high",
  "temperatureStatus": "normal" | "elevated" | "critical",
  "anomalyDetected": boolean,
  "irrigationRequired": boolean,
  "confidence": number (0-1),
  "summary": string,
  "recommendations": string[]
}

Base your analysis strictly on the provided sensor data and crop requirements.`;

  try {
    const response = await fetch(`${OPENROUTER_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://agriguard.ai',
        'X-Title': 'AgriGuard AI',
      },
      body: JSON.stringify({
        model,
        messages: [
          {
            role: 'system',
            content: 'You are an agricultural AI assistant. Always respond with valid JSON matching the specified schema. Do not include any text outside the JSON object.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature,
        max_tokens: maxTokens,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenRouter API error:', response.status, errorText);
      return null;
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;

    if (!content) {
      console.error('No content in AI response');
      return null;
    }

    // Try to extract JSON from the response
    let jsonContent = content.trim();
    
    // Handle markdown code blocks
    const jsonMatch = jsonContent.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      jsonContent = jsonMatch[1].trim();
    }

    const parsed = JSON.parse(jsonContent);
    
    // Validate with Zod
    const validated = aiAnalysisSchema.parse(parsed);
    
    return validated;
  } catch (error) {
    console.error('Error analyzing with AI:', error);
    return null;
  }
}
