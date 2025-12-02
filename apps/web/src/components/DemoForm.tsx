"use client";

// components/DemoForm.tsx (Form simple, submit à API)
import { useForm } from 'react-hook-form';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Calendar } from '@/components/ui/calendar'; // Shadcn calendar

type DemoFormValues = {
  name: string;
  email: string;
  hotel: string;
  date?: string;
};

export default function DemoForm() {
  const { register, handleSubmit, setValue } = useForm<DemoFormValues>();
  const onSubmit = (data: DemoFormValues) => console.log(data); // Envoyer à API NestJS

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <Label htmlFor="name">Nom</Label>
        <Input id="name" {...register('name')} />
      </div>
      <div>
        <Label htmlFor="email">Email</Label>
        <Input id="email" type="email" {...register('email')} />
      </div>
      <div>
        <Label htmlFor="hotel">Nom de l&apos;Hôtel</Label>
        <Input id="hotel" {...register('hotel')} />
      </div>
      <div>
        <Label>Sélectionnez une Date</Label>
        <Calendar mode="single" onChange={(value) => setValue('date', value)} /> {/* Scheduling basique */}
      </div>
      <Button type="submit" className="w-full">Planifier la Démo</Button>
    </form>
  );
}
