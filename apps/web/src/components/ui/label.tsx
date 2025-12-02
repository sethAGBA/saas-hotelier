"use client";

import * as React from "react";

type LabelProps = React.LabelHTMLAttributes<HTMLLabelElement>;

export const Label = React.forwardRef<HTMLLabelElement, LabelProps>(
  ({ className, ...props }, ref) => (
    <label
      ref={ref}
      className={`block text-sm font-medium text-slate-700 dark:text-slate-200 ${className ?? ""}`}
      {...props}
    />
  ),
);

Label.displayName = "Label";
