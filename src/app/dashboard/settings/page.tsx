'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getSystemConfig, updateSystemConfig, initializeSystemConfig, type SystemConfig } from '@/lib/firestore';
import { Card, CardHeader, CardTitle, CardContent, Badge, Skeleton, Button, Input, Label, Select } from '@/components/ui';
import { Settings as SettingsIcon, Brain, Cpu, Clock, ToggleLeft, AlertCircle } from 'lucide-react';

export default function SettingsPage() {
  const { userData } = useAuth();
  const [config, setConfig] = useState<SystemConfig | null>(null);
  const [models, setModels] = useState<Array<{ id: string; name: string }>>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [localConfig, setLocalConfig] = useState<Partial<SystemConfig>>({});

  useEffect(() => {
    async function loadSettings() {
      await initializeSystemConfig();
      const fetchedConfig = await getSystemConfig();
      setConfig(fetchedConfig);
      setLocalConfig(fetchedConfig || {});
      
      // Fetch available models
      try {
        const res = await fetch('/api/ai/models');
        if (res.ok) {
          const data = await res.json();
          setModels(data.models?.slice(0, 20) || []);
        }
      } catch (error) {
        console.error('Error fetching models:', error);
      }
      
      setLoading(false);
    }

    loadSettings();
  }, []);

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateSystemConfig(localConfig);
      setConfig({ ...config, ...localConfig, updatedAt: new Date() } as SystemConfig);
    } catch (error) {
      console.error('Error saving settings:', error);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        {Array.from({ length: 3 }).map((_, i) => (
          <Card key={i}>
            <CardContent className="p-6">
              <Skeleton className="h-64 w-full" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-gray-900">Settings</h2>
        <p className="text-gray-600 mt-1">Configure your farm and AI settings.</p>
      </div>

      {/* AI Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Brain className="h-5 w-5 text-green-600" />
            <CardTitle>AI Configuration</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="aiEnabled">AI Enabled</Label>
              <div className="mt-2">
                <button
                  onClick={() => setLocalConfig({ ...localConfig, aiEnabled: !localConfig.aiEnabled })}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    localConfig.aiEnabled ? 'bg-green-600' : 'bg-gray-200'
                  }`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      localConfig.aiEnabled ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Enable or disable AI analysis features
              </p>
            </div>

            <div>
              <Label htmlFor="selectedModel">AI Model</Label>
              <Select
                id="selectedModel"
                value={localConfig.selectedModel}
                onChange={(e) => setLocalConfig({ ...localConfig, selectedModel: e.target.value })}
                className="mt-2"
              >
                {models.length > 0 ? (
                  models.map((model) => (
                    <option key={model.id} value={model.id}>
                      {model.name || model.id}
                    </option>
                  ))
                ) : (
                  <>
                    <option value="google/gemma-3-27b-it:free">Google Gemma 3 27B (Free)</option>
                    <option value="meta-llama/llama-3-8b-instruct:free">Llama 3 8B Instruct (Free)</option>
                    <option value="mistralai/mistral-7b-instruct:free">Mistral 7B Instruct (Free)</option>
                  </>
                )}
              </Select>
              <p className="text-xs text-gray-500 mt-1">
                Select the OpenRouter model for AI analysis
              </p>
            </div>

            <div>
              <Label htmlFor="temperature">Temperature</Label>
              <Input
                id="temperature"
                type="number"
                step="0.1"
                min="0"
                max="2"
                value={localConfig.temperature ?? 0.2}
                onChange={(e) => setLocalConfig({ ...localConfig, temperature: parseFloat(e.target.value) })}
                className="mt-2"
              />
              <p className="text-xs text-gray-500 mt-1">
                Controls randomness (0-2). Lower = more deterministic
              </p>
            </div>

            <div>
              <Label htmlFor="maxTokens">Max Tokens</Label>
              <Input
                id="maxTokens"
                type="number"
                min="100"
                max="8192"
                value={localConfig.maxTokens ?? 1200}
                onChange={(e) => setLocalConfig({ ...localConfig, maxTokens: parseInt(e.target.value) })}
                className="mt-2"
              />
              <p className="text-xs text-gray-500 mt-1">
                Maximum tokens in AI response
              </p>
            </div>

            <div>
              <Label htmlFor="analysisIntervalMinutes">Analysis Interval</Label>
              <Input
                id="analysisIntervalMinutes"
                type="number"
                min="1"
                max="1440"
                value={localConfig.analysisIntervalMinutes ?? 10}
                onChange={(e) => setLocalConfig({ ...localConfig, analysisIntervalMinutes: parseInt(e.target.value) })}
                className="mt-2"
              />
              <p className="text-xs text-gray-500 mt-1">
                Minutes between automatic analyses
              </p>
            </div>
          </div>

          <div className="flex justify-end pt-4 border-t border-gray-100">
            <Button onClick={handleSave} disabled={saving}>
              {saving ? 'Saving...' : 'Save AI Settings'}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* System Status */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Cpu className="h-5 w-5 text-blue-600" />
            <CardTitle>System Status</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-500">AI Status</span>
                <Badge variant={config?.aiEnabled ? 'success' : 'default'}>
                  {config?.aiEnabled ? 'Active' : 'Disabled'}
                </Badge>
              </div>
              <p className="text-xs text-gray-600">
                Current model: {config?.selectedModel || 'Not configured'}
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-500">Maintenance Mode</span>
                <Badge variant={config?.maintenanceMode ? 'warning' : 'success'}>
                  {config?.maintenanceMode ? 'Enabled' : 'Disabled'}
                </Badge>
              </div>
              <p className="text-xs text-gray-600">
                System is {config?.maintenanceMode ? 'in maintenance' : 'operational'}
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-500">Default Farm</span>
                <span className="text-sm font-medium">{config?.defaultFarmId || 'Not set'}</span>
              </div>
              <p className="text-xs text-gray-600">
                Primary farm for dashboard
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-500">Last Updated</span>
                <span className="text-sm font-medium">
                  {config?.updatedAt ? new Date(config.updatedAt).toLocaleString() : 'Never'}
                </span>
              </div>
              <p className="text-xs text-gray-600">
                Last configuration change
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Information */}
      <Card className="border-blue-200 bg-blue-50">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-blue-600 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-blue-900">Configuration Notes</p>
              <ul className="text-xs text-blue-700 mt-2 space-y-1">
                <li>• Changes to AI settings take effect immediately for new analyses</li>
                <li>• The selected model is stored in Firestore and persists across sessions</li>
                <li>• Ensure your OpenRouter API key is configured in environment variables</li>
                <li>• Lower temperature values produce more consistent, deterministic results</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
