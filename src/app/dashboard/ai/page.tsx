'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getLatestAIAnalysis, getAIAnalysisHistory } from '@/lib/firestore';
import type { AIAnalysis } from '@/types';
import { Card, CardHeader, CardTitle, CardContent, Badge, Skeleton, Button } from '@/components/ui';
import { Brain, TrendingUp, AlertCircle, CheckCircle, Droplets, Thermometer, RefreshCw } from 'lucide-react';

export default function AIPage() {
  const { userData } = useAuth();
  const [latestAnalysis, setLatestAnalysis] = useState<AIAnalysis | null>(null);
  const [history, setHistory] = useState<AIAnalysis[]>([]);
  const [loading, setLoading] = useState(true);
  const [analyzing, setAnalyzing] = useState(false);

  useEffect(() => {
    async function loadAI() {
      if (!userData?.farmId) return;

      const latest = await getLatestAIAnalysis(userData.farmId);
      setLatestAnalysis(latest);

      // Get history for first zone
      const zones = await import('@/lib/firestore').then(m => m.getZones(userData.farmId));
      if (zones.length > 0) {
        const hist = await getAIAnalysisHistory(userData.farmId, zones[0].id, 10);
        setHistory(hist);
      }

      setLoading(false);
    }

    loadAI();
  }, [userData?.farmId]);

  const handleAnalyze = async () => {
    if (!userData?.farmId) return;
    
    setAnalyzing(true);
    try {
      const zones = await import('@/lib/firestore').then(m => m.getZones(userData.farmId));
      if (zones.length > 0) {
        const response = await fetch('/api/ai/analyze', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            farmId: userData.farmId,
            zoneId: zones[0].id,
          }),
        });

        if (response.ok) {
          const result = await response.json();
          setLatestAnalysis(result);
        }
      }
    } catch (error) {
      console.error('Error analyzing:', error);
    } finally {
      setAnalyzing(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <Card>
          <CardContent className="p-6">
            <Skeleton className="h-64 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">AI Intelligence Center</h2>
          <p className="text-gray-600 mt-1">AI-powered crop health analysis and recommendations.</p>
        </div>
        <Button onClick={handleAnalyze} disabled={analyzing || !userData?.farmId}>
          <RefreshCw className={`h-4 w-4 mr-2 ${analyzing ? 'animate-spin' : ''}`} />
          {analyzing ? 'Analyzing...' : 'Analyze Current Conditions'}
        </Button>
      </div>

      {/* Latest Analysis */}
      <Card className="border-green-200 bg-gradient-to-br from-green-50 to-white">
        <CardHeader>
          <div className="flex items-center gap-2">
            <div className="p-2 bg-green-600 rounded-lg">
              <Brain className="h-5 w-5 text-white" />
            </div>
            <CardTitle className="text-green-900">Latest AI Analysis</CardTitle>
            {latestAnalysis && (
              <Badge variant="info" className="ml-auto">
                Model: {latestAnalysis.model}
              </Badge>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {latestAnalysis ? (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div className="space-y-6">
                {/* Health Score */}
                <div className="text-center p-6 bg-white rounded-xl border border-green-200">
                  <p className="text-sm text-gray-500 mb-2">Plant Health Score</p>
                  <p className="text-5xl font-bold text-green-600">{latestAnalysis.healthScore}</p>
                  <p className="text-sm text-gray-500 mt-1">out of 100</p>
                  <Badge 
                    variant={
                      latestAnalysis.healthStatus === 'healthy' ? 'success' : 
                      latestAnalysis.healthStatus === 'stressed' ? 'warning' : 'danger'
                    }
                    className="mt-3"
                  >
                    {latestAnalysis.healthStatus.toUpperCase()}
                  </Badge>
                </div>

                {/* Status Indicators */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200">
                    <div className="flex items-center gap-3">
                      <Droplets className="h-5 w-5 text-blue-600" />
                      <span className="text-sm font-medium">Water Stress</span>
                    </div>
                    <Badge variant={
                      latestAnalysis.waterStress === 'low' ? 'success' :
                      latestAnalysis.waterStress === 'medium' ? 'warning' : 'danger'
                    }>
                      {latestAnalysis.waterStress}
                    </Badge>
                  </div>

                  <div className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200">
                    <div className="flex items-center gap-3">
                      <Thermometer className="h-5 w-5 text-orange-600" />
                      <span className="text-sm font-medium">Temperature</span>
                    </div>
                    <Badge variant={
                      latestAnalysis.temperatureStatus === 'normal' ? 'success' :
                      latestAnalysis.temperatureStatus === 'elevated' ? 'warning' : 'danger'
                    }>
                      {latestAnalysis.temperatureStatus}
                    </Badge>
                  </div>

                  <div className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200">
                    <div className="flex items-center gap-3">
                      {latestAnalysis.anomalyDetected ? (
                        <AlertCircle className="h-5 w-5 text-red-600" />
                      ) : (
                        <CheckCircle className="h-5 w-5 text-green-600" />
                      )}
                      <span className="text-sm font-medium">Anomaly Detection</span>
                    </div>
                    <Badge variant={latestAnalysis.anomalyDetected ? 'danger' : 'success'}>
                      {latestAnalysis.anomalyDetected ? 'Detected' : 'None'}
                    </Badge>
                  </div>

                  <div className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200">
                    <div className="flex items-center gap-3">
                      <TrendingUp className="h-5 w-5 text-purple-600" />
                      <span className="text-sm font-medium">Confidence</span>
                    </div>
                    <span className="text-sm font-semibold">
                      {(latestAnalysis.confidence * 100).toFixed(0)}%
                    </span>
                  </div>
                </div>
              </div>

              <div className="space-y-6">
                {/* Summary */}
                <div className="p-4 bg-white rounded-lg border border-gray-200">
                  <h4 className="text-sm font-semibold text-gray-700 mb-2">AI Summary</h4>
                  <p className="text-gray-600 text-sm leading-relaxed">{latestAnalysis.summary}</p>
                </div>

                {/* Recommendations */}
                <div className="p-4 bg-white rounded-lg border border-gray-200">
                  <h4 className="text-sm font-semibold text-gray-700 mb-3">Recommendations</h4>
                  <ul className="space-y-2">
                    {latestAnalysis.recommendations.map((rec, index) => (
                      <li key={index} className="flex items-start gap-2 text-sm text-gray-600">
                        <span className="text-green-600 mt-1 flex-shrink-0">•</span>
                        {rec}
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Irrigation Recommendation */}
                {latestAnalysis.irrigationRequired && (
                  <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <div className="flex items-start gap-3">
                      <AlertCircle className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
                      <div>
                        <p className="text-sm font-medium text-yellow-900">Irrigation Recommended</p>
                        <p className="text-xs text-yellow-700 mt-1">
                          The AI system recommends initiating irrigation based on current soil conditions.
                        </p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          ) : (
            <div className="text-center py-12">
              <Brain className="h-16 w-16 text-gray-300 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No AI Analysis Available</h3>
              <p className="text-gray-500 mb-4">Click &quot;Analyze Current Conditions&quot; to generate an AI analysis.</p>
              <p className="text-xs text-gray-400">Requires sensor data and OpenRouter API configuration.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Analysis History */}
      <Card>
        <CardHeader>
          <CardTitle>Analysis History</CardTitle>
        </CardHeader>
        <CardContent>
          {history.length > 0 ? (
            <div className="space-y-3">
              {history.map((analysis) => (
                <div 
                  key={analysis.id} 
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    <div className={`h-10 w-10 rounded-full flex items-center justify-center ${
                      analysis.healthStatus === 'healthy' ? 'bg-green-100' :
                      analysis.healthStatus === 'stressed' ? 'bg-yellow-100' : 'bg-red-100'
                    }`}>
                      <Brain className={`h-5 w-5 ${
                        analysis.healthStatus === 'healthy' ? 'text-green-600' :
                        analysis.healthStatus === 'stressed' ? 'text-yellow-600' : 'text-red-600'
                      }`} />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        Health Score: {analysis.healthScore} - {analysis.healthStatus}
                      </p>
                      <p className="text-xs text-gray-500">
                        {analysis.createdAt ? new Date(analysis.createdAt).toLocaleString() : '--'}
                      </p>
                    </div>
                  </div>
                  <Badge variant={
                    analysis.healthStatus === 'healthy' ? 'success' :
                    analysis.healthStatus === 'stressed' ? 'warning' : 'danger'
                  }>
                    {analysis.model}
                  </Badge>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-gray-500">No analysis history available yet.</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
