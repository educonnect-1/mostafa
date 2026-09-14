import { NextResponse } from 'next/server';
import { analyzeWithAI, getOpenRouterModels } from '@/lib/openrouter';
import { getSystemConfig, getLatestSensorReading, getSensorHistory, getCropProfile, saveAIAnalysis, getZones } from '@/lib/firestore';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { farmId, zoneId } = body;

    if (!farmId || !zoneId) {
      return NextResponse.json(
        { error: 'Missing farmId or zoneId' },
        { status: 400 }
      );
    }

    // Get system config
    const config = await getSystemConfig();
    if (!config || !config.aiEnabled) {
      return NextResponse.json(
        { error: 'AI is disabled' },
        { status: 400 }
      );
    }

    const model = config.selectedModel || 'google/gemma-3-27b-it:free';

    // Get latest sensor reading
    const sensorReading = await getLatestSensorReading(farmId, zoneId);
    if (!sensorReading) {
      return NextResponse.json(
        { error: 'No sensor readings available' },
        { status: 400 }
      );
    }

    // Get historical data
    const history = await getSensorHistory(farmId, zoneId, 24);
    const historicalData = history.map(h => ({
      timestamp: h.timestamp,
      soilMoisture: h.soilMoisture,
      temperature: h.temperature,
      humidity: h.humidity,
    }));

    // Get crop profile based on zone
    const zones = await getZones(farmId);
    const zone = zones.find(z => z.id === zoneId);
    const cropType = zone?.cropType || 'tomato';
    
    let cropProfile = await getCropProfile(cropType);
    if (!cropProfile) {
      // Default crop profile
      cropProfile = {
        id: 'default',
        name: cropType,
        minimumMoisture: 35,
        targetMoisture: 55,
        maximumMoisture: 70,
        minTemperature: 18,
        maxTemperature: 32,
        description: 'Default crop profile',
        createdAt: new Date(),
      };
    }

    // Run AI analysis
    const analysis = await analyzeWithAI(
      model,
      {
        soilMoisture: sensorReading.soilMoisture,
        temperature: sensorReading.temperature,
        humidity: sensorReading.humidity,
        waterLevel: sensorReading.waterLevel,
        flowRate: sensorReading.flowRate,
        lightLevel: sensorReading.lightLevel,
        pumpStatus: sensorReading.pumpStatus,
        deviceStatus: sensorReading.deviceStatus,
      },
      {
        name: cropProfile.name,
        minimumMoisture: cropProfile.minimumMoisture,
        targetMoisture: cropProfile.targetMoisture,
        maximumMoisture: cropProfile.maximumMoisture,
        minTemperature: cropProfile.minTemperature,
        maxTemperature: cropProfile.maxTemperature,
      },
      historicalData,
      config.temperature,
      config.maxTokens
    );

    if (!analysis) {
      return NextResponse.json(
        { error: 'Failed to generate AI analysis' },
        { status: 500 }
      );
    }

    // Save analysis to Firestore
    const analysisId = await saveAIAnalysis({
      farmId,
      zoneId,
      model,
      ...analysis,
    });

    return NextResponse.json({
      id: analysisId,
      ...analysis,
    });
  } catch (error) {
    console.error('Error in AI analysis:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
