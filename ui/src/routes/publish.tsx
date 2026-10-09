import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { Button } from "@/components/ui/button";
import { Input, Label, Textarea } from "@/components/ui/input";
import { useOmart } from "@/lib/omart/store";
import { KINDS, LISTING_ID_PATTERN, LISTING_ID_HELP, type PluginKind } from "@/lib/omart/types";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/publish")({ component: PublishPage });

function PublishPage() {
  const publish = useOmart((s) => s.publish);
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);
  const [kinds, setKinds] = useState<PluginKind[]>(["bar-widget"]);

  function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const data = new FormData(e.currentTarget);
    const id = String(data.get("id") ?? "").trim();
    const name = String(data.get("name") ?? "").trim();
    const git = String(data.get("git") ?? "").trim();
    const description = String(data.get("description") ?? "").trim();
    const author = String(data.get("author") ?? "").trim();
    const version = String(data.get("version") ?? "0.1.0").trim();
    const tags = String(data.get("tags") ?? "")
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);

    if (!id || !name || !git || !description) {
      setError("Id, name, git URL, and description are required.");
      return;
    }
    if (kinds.length === 0) {
      setError("Pick at least one kind.");
      return;
    }

    void publish({
      id,
      name,
      git,
      description,
      author: author || "you",
      version,
      tags,
      kinds,
      category: "tools",
      license: "MIT",
    }).then((err) => {
      if (err) {
        setError(err);
        return;
      }
      void navigate({ to: "/plugin/$id", params: { id } });
    });
  }

  return (
    <div className="max-w-xl">
      <p className="font-mono text-[11px] tracking-wide text-subtle uppercase">publish</p>
      <h1 className="mt-2 font-display text-4xl tracking-tight italic">Publish a listing</h1>
      <p className="mt-3 text-sm leading-relaxed text-muted">
        Your listing hops out through pals as a rumor with a git URL. Bump the version if you mean a
        new one — identical listings are ignored.
      </p>

      <form onSubmit={onSubmit} className="mt-8 space-y-5">
        <div>
          <Label htmlFor="id">listing ID</Label>
          <Input id="id" name="id" placeholder="yourname-plugin" pattern={LISTING_ID_PATTERN}
            title={LISTING_ID_HELP} required aria-describedby="id-help" className="mt-1.5" />
          <p id="id-help" className="mt-2 text-xs leading-relaxed text-muted">
            {LISTING_ID_HELP} This is your Omart listing key. Your repository’s manifest.json
            keeps its own plugin ID; Omarchy installs from the Git URL below.
          </p>
        </div>
        <Field name="name" label="name" placeholder="Plugin name" />
        <Field name="git" label="git" placeholder="https://github.com/you/plugin.git" />
        <div className="grid gap-5 sm:grid-cols-2">
          <Field name="author" label="author" placeholder="your name" />
          <Field name="version" label="version" placeholder="0.1.0" defaultValue="0.1.0" />
        </div>
        <div>
          <Label htmlFor="description">description</Label>
          <Textarea id="description" name="description" className="mt-1.5" rows={4} />
        </div>
        <Field name="tags" label="tags" placeholder="bar, weather, focus" />

        <fieldset>
          <legend className="text-sm font-medium text-muted">kinds</legend>
          <div className="mt-2 flex flex-wrap gap-2">
            {KINDS.map((k) => {
              const on = kinds.includes(k);
              return (
                <button
                  key={k}
                  type="button"
                  onClick={() =>
                    setKinds(on ? kinds.filter((x) => x !== k) : [...kinds, k])
                  }
                  className={cn(
                    "h-8 rounded-full px-3 font-mono text-[11px]",
                    on ? "bg-accent text-accent-fg" : "bg-raised text-muted shadow-[var(--shadow-border)]",
                  )}
                >
                  {k}
                </button>
              );
            })}
          </div>
        </fieldset>

        {error && <p className="text-sm text-danger">{error}</p>}

        <Button type="submit">Publish</Button>
      </form>


    </div>
  );
}

function Field({
  name,
  label,
  placeholder,
  defaultValue,
}: {
  name: string;
  label: string;
  placeholder?: string;
  defaultValue?: string;
}) {
  return (
    <div>
      <Label htmlFor={name}>{label}</Label>
      <Input
        id={name}
        name={name}
        placeholder={placeholder}
        defaultValue={defaultValue}
        className="mt-1.5"
      />
    </div>
  );
}
