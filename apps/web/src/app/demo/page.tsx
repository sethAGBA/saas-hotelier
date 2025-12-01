import DemoForm from '@/components/DemoForm';

export default function DemoPage() {
  return (
    <section className="container mx-auto py-16">
      <h1 className="text-3xl font-bold mb-6">Demandez une démo</h1>
      <p className="mb-6">Remplissez le formulaire pour planifier une démonstration avec notre équipe.</p>
      <DemoForm />
    </section>
  );
}
