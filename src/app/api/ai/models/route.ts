import { NextResponse } from 'next/server';
import { getOpenRouterModels } from '@/lib/openrouter';

export async function GET() {
  try {
    const models = await getOpenRouterModels();
    return NextResponse.json({ models });
  } catch (error) {
    console.error('Error fetching models:', error);
    return NextResponse.json(
      { error: 'Failed to fetch models' },
      { status: 500 }
    );
  }
}
