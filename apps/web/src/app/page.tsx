// app/page.tsx
import Hero from '@/components/Hero';
import Benefits from '@/components/Benefits';
import Features from '@/components/Features';
import Testimonials from '@/components/Testimonials';
import Timeline from '@/components/Timeline';
import Integrations from '@/components/Integrations';
import FAQ from '@/components/FAQ';
import CTA from '@/components/CTA';

export default function Home() {
  return (
    <main>
      <Hero />
      <Benefits />
      <Features />
      <Testimonials />
      <Timeline />
      <Integrations />
      <FAQ />
      <CTA />
    </main>
  );
}