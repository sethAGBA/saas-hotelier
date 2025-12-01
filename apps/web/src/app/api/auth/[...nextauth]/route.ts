// Minimal placeholder for NextAuth route. Replace with real NextAuth config.
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ message: 'NextAuth placeholder (GET)' });
}

export async function POST() {
  return NextResponse.json({ message: 'NextAuth placeholder (POST)' });
}
