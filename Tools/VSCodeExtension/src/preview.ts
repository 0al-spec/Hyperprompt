export const escapeHtml = (value: string): string => {
	return value
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;')
		.replace(/'/g, '&#39;');
};

export const buildPreviewHtml = (markdown: string): string => {
	const content = markdown.trim().length > 0 ? markdown : 'No preview output.';
	const escaped = escapeHtml(content);
	return `<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<title>Hyperprompt Preview</title>
	<style>
		:root {
			color-scheme: light dark;
		}
		body {
			font-family: ui-serif, Georgia, Cambria, "Times New Roman", Times, serif;
			margin: 0;
			padding: 24px;
			background: var(--vscode-editor-background);
			color: var(--vscode-editor-foreground);
		}
		pre {
			white-space: pre-wrap;
			word-break: break-word;
			line-height: 1.5;
			font-size: 14px;
			background: var(--vscode-editor-inactiveSelectionBackground);
			padding: 16px;
			border-radius: 8px;
		}
	</style>
</head>
<body>
	<pre>${escaped}</pre>
</body>
</html>`;
};
