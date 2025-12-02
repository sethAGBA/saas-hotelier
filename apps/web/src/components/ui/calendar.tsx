"use client";

import * as React from "react";

type CalendarProps = {
  className?: string;
  mode?: "single";
  onChange?: (value: string) => void;
} & Omit<React.InputHTMLAttributes<HTMLInputElement>, "type" | "onChange">;

export function Calendar({ className, mode = "single", onChange, ...props }: CalendarProps) {
  // Simplified date picker placeholder; replace with a real calendar when adding a UI library.
  return (
    <input
      type="date"
      className={`w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 ${className ?? ""}`}
      onChange={(e) => onChange?.(e.target.value)}
      aria-label={mode === "single" ? "Select a date" : "Select dates"}
      {...props}
    />
  );
}
