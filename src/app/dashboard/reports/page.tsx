'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getIrrigationLogs, getLatestSensorReading, getLatestAIAnalysis } from '@/lib/firestore';
import type { IrrigationLog, SensorReading, AIAnalysis } from '@/types';
import { Card, CardHeader, CardTitle, CardContent, Badge, Skeleton, Button } from '@/components/ui';
import { Droplets, Thermometer, Leaf, TrendingUp, FileText, Calendar, BarChart3 } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';

export default function ReportsPage() {
  const { userData } = useAuth();
  const [logs, setLogs] = useState<IrrigationLog[]>([]);
  const [latestReading, setLatestReading] = useState<SensorReading | null>(null);
  const [aiAnalysis, setAIAnalysis] = useState<AIAnalysis | null>(null);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);

  useEffect(() => {
    async function loadReports() {
      if (!userData?.farmId) return;

      const [fetchedLogs, reading, analysis] = await Promise.all([
        getIrrigationLogs(userData.farmId),
        getLatestSensorReading(userData.farmId),
        getLatestAIAnalysis(userData.farmId),
      ]);

      setLogs(fetchedLogs);
      setLatestReading(reading);
      setAIAnalysis(analysis);
      setLoading(false);
    }

    loadReports();
  }, [userData?.farmId]);

  const handleGenerateReport = async () => {
    setGenerating(true);
    // In a real implementation, this would call an API to generate a PDF report
    setTimeout(() => setGenerating(false), 2000);
  };

  // Prepare chart data
  const waterUsageData = logs.slice(0, 7).map(log => ({
    name: log.startedAt ? new Date(log.startedAt).toLocaleDateString(undefined, { weekday: 'short' }) : 'N/A',
    usage: log.waterUsedLiters || 0,
  })).reverse();

  const irrigationTriggerData = [
    { name: 'Automatic', value: logs.filter(l => l.trigger === 'automatic').length },
    { name: 'Manual', value: logs.filter(l => l.trigger === 'manual').length },
    { name: 'AI', value: logs.filter(l => l.trigger === 'ai_recommendation').length },
    { name: 'Emergency', value: logs.filter(l => l.trigger === 'emergency').length },
  ].filter(d => d.value > 0);

  const COLORS = ['#16a34a', '#3b82f6', '#8b5cf6', '#ef4444'];

  const totalWaterUsed = logs.reduce((sum, log) => sum + (log.waterUsedLiters || 0), 0);
  const avgMoisture = latestReading?.soilMoisture || 0;
  const avgTemp = latestReading?.temperature || 0;
  const healthScore = aiAnalysis?.healthScore || 0;

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="p-6">
                <Skeleton className="h-4 w-24 mb-4" />
                <Skeleton className="h-8 w-32" />
              </CardContent>
            </Card>
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card><CardContent className="p-6"><Skeleton className="h-64 w-full" /></CardContent></Card>
          <Card><CardContent className="p-6"><Skeleton className="h-64 w-full" /></CardContent></Card>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">Farm Reports</h2>
          <p className="text-gray-600 mt-1">Overview of farm performance and analytics.</p>
        </div>
        <Button onClick={handleGenerateReport} disabled={generating}>
          <FileText className="h-4 w-4 mr-2" />
          {generating ? 'Generating...' : 'Generate AI Report'}
        </Button>
      </div>

      {/* Summary Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <Droplets className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Total Water Used</p>
                <p className="text-lg font-semibold text-gray-900">{totalWaterUsed.toFixed(1)} L</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-100 rounded-lg">
                <Thermometer className="h-5 w-5 text-orange-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Avg Temperature</p>
                <p className="text-lg font-semibold text-gray-900">{avgTemp.toFixed(1)}°C</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-100 rounded-lg">
                <Leaf className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Plant Health</p>
                <p className="text-lg font-semibold text-gray-900">{healthScore}/100</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 rounded-lg">
                <TrendingUp className="h-5 w-5 text-purple-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Irrigation Cycles</p>
                <p className="text-lg font-semibold text-gray-900">{logs.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Water Usage (Last 7 Events)</CardTitle>
          </CardHeader>
          <CardContent>
            {waterUsageData.length > 0 ? (
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={waterUsageData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis dataKey="name" stroke="#9ca3af" fontSize={12} />
                    <YAxis stroke="#9ca3af" fontSize={12} unit="L" />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#fff',
                        border: '1px solid #e5e7eb',
                        borderRadius: '8px'
                      }}
                    />
                    <Bar dataKey="usage" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="h-64 flex items-center justify-center">
                <p className="text-gray-500">No water usage data available</p>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Irrigation Triggers</CardTitle>
          </CardHeader>
          <CardContent>
            {irrigationTriggerData.length > 0 ? (
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={irrigationTriggerData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {irrigationTriggerData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="h-64 flex items-center justify-center">
                <p className="text-gray-500">No irrigation data available</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* AI Insights Summary */}
      {aiAnalysis && (
        <Card className="border-green-200 bg-green-50">
          <CardHeader>
            <div className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-600" />
              <CardTitle className="text-green-900">AI Insights Summary</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-green-800 mb-2">Health Assessment</p>
                <p className="text-sm text-green-700">{aiAnalysis.summary}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-green-800 mb-2">Key Recommendations</p>
                <ul className="space-y-1">
                  {aiAnalysis.recommendations.slice(0, 3).map((rec, index) => (
                    <li key={index} className="text-sm text-green-700 flex items-start gap-2">
                      <span className="text-green-600 mt-0.5">•</span>
                      {rec}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Daily Summary Table */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Irrigation Activity</CardTitle>
        </CardHeader>
        <CardContent>
          {logs.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Date</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Trigger</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Duration</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Water Used</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {logs.slice(0, 10).map((log) => (
                    <tr key={log.id} className="border-b border-gray-100">
                      <td className="py-3 px-4 text-sm text-gray-600">
                        {log.startedAt ? new Date(log.startedAt).toLocaleDateString() : '--'}
                      </td>
                      <td className="py-3 px-4 text-sm">
                        <Badge variant={
                          log.trigger === 'automatic' ? 'info' :
                          log.trigger === 'ai_recommendation' ? 'success' :
                          log.trigger === 'emergency' ? 'danger' : 'default'
                        }>
                          {log.trigger.replace('_', ' ')}
                        </Badge>
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600">
                        {Math.floor((log.durationSeconds || 0) / 60)}m {(log.durationSeconds || 0) % 60}s
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600">
                        {log.waterUsedLiters?.toFixed(1) || 0} L
                      </td>
                      <td className="py-3 px-4 text-sm">
                        <Badge variant={log.status === 'completed' ? 'success' : log.status === 'failed' ? 'danger' : 'default'}>
                          {log.status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-gray-500">No irrigation activity recorded yet.</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
