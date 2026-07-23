import { z, defineCollection } from "astro:content";
import { glob } from "astro/loaders";

const postsCollection = defineCollection({
    loader: glob({ pattern: "**/*.md", base: "./src/content/posts" }),
    schema: z.object({
        title: z.string(),
        description: z.string(),
        date: z.date(),
        tags: z.array(z.string()).default([]),
        image: z.string().optional(),
        imageAlt: z.string().optional(),
        readingTime: z.string().default("5 min read"),
    }),
});

const projectsCollection = defineCollection({
    loader: glob({ pattern: "**/*.md", base: "./src/content/projects" }),
    schema: z.object({
        title: z.string(),
        year: z.number(),
        month: z.number().min(1).max(12),
        description: z.string(),
        tags: z.array(z.string()).default([]),
        href: z.string(),
    }),
});

export const collections = {
    posts: postsCollection,
    projects: projectsCollection,
};
