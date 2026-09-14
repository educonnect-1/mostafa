import { z } from 'zod';

// AI Analysis Output Schema
export const aiAnalysisSchema = z.object({
  healthScore: z.number().min(0).max(100),
  healthStatus: z.enum(['healthy', 'stressed', 'critical']),
  waterStress: z.enum(['low', 'medium', 'high']),
  temperatureStatus: z.enum(['normal', 'elevated', 'critical']),
  anomalyDetected: z.boolean(),
  irrigationRequired: z.boolean(),
  confidence: z.number().min(0).max(1),
  summary: z.string(),
  recommendations: z.array(z.string()),
});

export type AIAnalysisOutput = z.infer<typeof aiAnalysisSchema>;

// System Config Schema
export const systemConfigSchema = z.object({
  selectedModel: z.string(),
  aiEnabled: z.boolean(),
  temperature: z.number().min(0).max(2),
  maxTokens: z.number().min(100).max(8192),
  analysisIntervalMinutes: z.number().min(1).max(1440),
  defaultFarmId: z.string(),
  maintenanceMode: z.boolean(),
  updatedAt: z.date(),
});

// Sensor Reading Schema
export const sensorReadingSchema = z.object({
  soilMoisture: z.number().min(0).max(100),
  temperature: z.number().min(-50).max(60),
  humidity: z.number().min(0).max(100),
  waterLevel: z.number().min(0).max(100),
  flowRate: z.number().min(0),
  lightLevel: z.number().min(0).max(100),
  pumpStatus: z.boolean(),
  deviceStatus: z.enum(['online', 'offline']),
});
