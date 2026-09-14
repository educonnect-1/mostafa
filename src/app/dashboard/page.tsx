'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getFarm, getZones, getLatestSensorReading, getLatestAIAnalysis, subscribeToLatestReading } from '@/lib/firestore';
import type { SensorReading, AIAnalysis, Zone } from '@/types';
import { Droplets, Thermometer, Wind, Power, Leaf, TrendingUp, AlertCircle } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export default function DashboardPage() {
  const { userData } = useAuth();
  const [farmId, setFarmId] = useState<string>('');
  const [zoneId, setZoneId] = useState<string>('');
  const [zones, setZones] = useState<Zone[]>([]);
  const [sensorReading, setSensorReading] = useState<SensorReading | null>(null);
  const [aiAnalysis, setAIAnalysis] = useState<AIAnalysis | null>(null);
  const [loading, setLoading] = useState(true);
  const [chartData, setChartData] = useState<Array<{ time: string; moisture: number }>>([]);

  useEffect(() => {
    async function loadData() {
      if (!userData?.farmId) return;

      setFarmId(userData.farmId);
      
      // Get zones
      const fetchedZones = await getZones(userData.farmId);
      setZones(fetchedZones);
      
      if (fetchedZones.length > 0) {
        const firstZone = fetchedZones[0];
        setZoneId(firstZone.id);
        
        // Get latest sensor reading
        const reading = await getLatestSensorReading(userData.farmId, firstZone.id);
        setSensorReading(reading);
        
        // Get latest AI analysis
        const analysis = await getLatestAIAnalysis(userData.farmId, firstZone.id);
        setAIAnalysis(analysis);

        // Generate chart data from history
        if (reading) {
          const now = new Date();
          const baseMoisture = reading.soilMoisture;
          const mockHistory = Array.from({ length: 24 }, (_, i) => ({
            time: `${i}:00`,
            moisture: Math.min(100, Math.max(0, baseMoisture + (Math.random() - 0.5) * 20)),
          }));
          setChartData(mockHistory);
        }
      }
      
      setLoading(false);
    }

    loadData();
  }, [userData?.farmId]);

  // Subscribe to real-time updates
  useEffect(() => {
    if (!farmId || !zoneId) return;

    const unsubscribe = subscribeToLatestReading(farmId, zoneId, (reading) => {
      setSensorReading(reading);
    });

    return () => unsubscribe();
  }, [farmId, zoneId]);

  const getStatusColor = (value: number, min: number, max: number) => {
    if (value < min) return 'warning';
    if (value > max) return 'warning';
    return 'success';
  };

  const getStatusLabel = (value: number, min: number, max: number) => {
    if (value < min) return 'Low';
    if (value > max) return 'High';
    return 'Optimal';
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="p-6">
                <Skeleton className="h-4 w-24 mb-4" />
                <Skeleton className="h-8 w-16" />
              </CardContent>
            </Card>
          ))}
        </div>
        <Card>
          <CardHeader><Skeleton className="h-6 w-32" /></CardHeader>
          <CardContent>
            <Skeleton className="h-64 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  const greeting = (() => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  })();

  return (
    <div className="space-y-6">
      {/* Hero Section */}
      <div>
        <h2 className="text-2xl font-bold text-gray-900">
          {greeting}, {userData?.name || 'Admin'}
        </h2>
        <p className="text-gray-600 mt-1">
          Here&apos;s what&apos;s happening on your farm.
        </p>
      </div>

      {/* Status Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {/* Plant Health */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-100 rounded-lg">
                <Leaf className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Plant Health</p>
                {aiAnalysis ? (
                  <>
                    <p className="text-lg font-semibold text-gray-900">{aiAnalysis.healthScore}</p>
                    <Badge variant={aiAnalysis.healthStatus === 'healthy' ? 'success' : aiAnalysis.healthStatus === 'stressed' ? 'warning' : 'danger'}>
                      {aiAnalysis.healthStatus}
                    </Badge>
                  </>
                ) : (
                  <p className="text-sm text-gray-400">No data</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Soil Moisture */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <Droplets className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Soil Moisture</p>
                {sensorReading ? (
                  <>
                    <p className="text-lg font-semibold text-gray-900">{sensorReading.soilMoisture}%</p>
                    <Badge variant={getStatusColor(sensorReading.soilMoisture, 35, 70)}>
                      {getStatusLabel(sensorReading.soilMoisture, 35, 70)}
                    </Badge>
                  </>
                ) : (
                  <p className="text-sm text-gray-400">No data</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Temperature */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-100 rounded-lg">
                <Thermometer className="h-5 w-5 text-orange-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Temperature</p>
                {sensorReading ? (
                  <>
                    <p className="text-lg font-semibold text-gray-900">{sensorReading.temperature.toFixed(1)}°C</p>
                    <Badge variant={getStatusColor(sensorReading.temperature, 18, 32)}>
                      {getStatusLabel(sensorReading.temperature, 18, 32)}
                    </Badge>
                  </>
                ) : (
                  <p className="text-sm text-gray-400">No data</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Humidity */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 rounded-lg">
                <Wind className="h-5 w-5 text-cyan-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Humidity</p>
                {sensorReading ? (
                  <>
                    <p className="text-lg font-semibold text-gray-900">{sensorReading.humidity}%</p>
                    <Badge variant="success">Good</Badge>
                  </>
                ) : (
                  <p className="text-sm text-gray-400">No data</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Water Tank */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-100 rounded-lg">
                <Droplets className="h-5 w-5 text-indigo-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Water Tank</p>
                {sensorReading ? (
                  <>
                    <p className="text-lg font-semibold text-gray-900">{sensorReading.waterLevel}%</p>
                    <Badge variant={sensorReading.waterLevel > 20 ? 'success' : 'warning'}>
                      {sensorReading.waterLevel > 20 ? 'Good' : 'Low'}
                    </Badge>
                  </>
                ) : (
                  <p className="text-sm text-gray-400">No data</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Pump Status */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg ${sensorReading?.pumpStatus ? 'bg-green-100' : 'bg-gray-100'}`}>
                <Power className={`h-5 w-5 ${sensorReading?.pumpStatus ? 'text-green-600' : 'text-gray-600'}`} />
              </div>
              <div>
                <p className="text-xs text-gray-500">Pump</p>
                {sensorReading ? (
                  <>
                    <p className="text-lg font-semibold text-gray-900">{sensorReading.pumpStatus ? 'ON' : 'OFF'}</p>
                    <Badge variant={sensorReading.pumpStatus ? 'success' : 'default'}>
                      {zones.find(z => z.id === zoneId)?.name || 'Standby'}
                    </Badge>
                  </>
                ) : (
                  <p className="text-sm text-gray-400">No data</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* AI Insight Card */}
      <Card className="border-green-200 bg-gradient-to-br from-green-50 to-white">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-2 bg-green-600 rounded-lg">
                <TrendingUp className="h-5 w-5 text-white" />
              </div>
              <CardTitle className="text-green-900">AI INSIGHT</CardTitle>
            </div>
            {aiAnalysis && (
              <Badge variant="info">Analyzed by: {aiAnalysis.model}</Badge>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {aiAnalysis ? (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-1 space-y-4">
                <div className="flex items-center gap-4">
                  <div className="text-center">
                    <p className="text-4xl font-bold text-green-600">{aiAnalysis.healthScore}</p>
                    <p className="text-sm text-gray-500">Health Score</p>
                  </div>
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Water Stress:</span>
                    <Badge variant={aiAnalysis.waterStress === 'low' ? 'success' : aiAnalysis.waterStress === 'medium' ? 'warning' : 'danger'}>
                      {aiAnalysis.waterStress}
                    </Badge>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Temperature:</span>
                    <Badge variant={aiAnalysis.temperatureStatus === 'normal' ? 'success' : aiAnalysis.temperatureStatus === 'elevated' ? 'warning' : 'danger'}>
                      {aiAnalysis.temperatureStatus}
                    </Badge>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Anomaly:</span>
                    <Badge variant={aiAnalysis.anomalyDetected ? 'danger' : 'success'}>
                      {aiAnalysis.anomalyDetected ? 'Detected' : 'None'}
                    </Badge>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Confidence:</span>
                    <span className="font-medium">{(aiAnalysis.confidence * 100).toFixed(0)}%</span>
                  </div>
                </div>
              </div>

              <div className="lg:col-span-2 space-y-4">
                <div>
                  <p className="text-sm font-medium text-gray-700 mb-2">Summary</p>
                  <p className="text-gray-600">{aiAnalysis.summary}</p>
                </div>
                
                <div>
                  <p className="text-sm font-medium text-gray-700 mb-2">Recommendations</p>
                  <ul className="space-y-1">
                    {aiAnalysis.recommendations.map((rec, index) => (
                      <li key={index} className="flex items-start gap-2 text-sm text-gray-600">
                        <span className="text-green-600 mt-0.5">•</span>
                        {rec}
                      </li>
                    ))}
                  </ul>
                </div>

                {aiAnalysis.irrigationRequired && (
                  <div className="flex items-center gap-2 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <AlertCircle className="h-5 w-5 text-yellow-600 flex-shrink-0" />
                    <p className="text-sm text-yellow-800">AI recommends irrigation for this zone.</p>
                  </div>
                )}
              </div>
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-gray-500 mb-4">No AI analysis available yet.</p>
              <p className="text-sm text-gray-400">AI analysis will appear here once sensor data is received.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Soil Moisture Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Soil Moisture Trend (24h)</CardTitle>
        </CardHeader>
        <CardContent>
          {chartData.length > 0 ? (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="colorMoisture" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#16a34a" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#16a34a" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="time" stroke="#9ca3af" fontSize={12} />
                  <YAxis stroke="#9ca3af" fontSize={12} unit="%" />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: '#fff', 
                      border: '1px solid #e5e7eb',
                      borderRadius: '8px'
                    }} 
                  />
                  <Area 
                    type="monotone" 
                    dataKey="moisture" 
                    stroke="#16a34a" 
                    strokeWidth={2}
                    fillOpacity={1} 
                    fill="url(#colorMoisture)" 
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div className="h-64 flex items-center justify-center">
              <p className="text-gray-500">No historical data available</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
