#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const logFile = process.env.HYPERPROMPT_TEST_LOG;

const logRequest = (payload) => {
	if (!logFile) {
		return;
	}
	try {
		fs.appendFileSync(logFile, `${JSON.stringify(payload)}\n`);
	} catch {
		// ignore log errors in tests
	}
};

const writeResponse = (response) => {
	process.stdout.write(`${JSON.stringify(response)}\n`);
};

const args = process.argv.slice(2);
if (args.includes('--help')) {
	process.stdout.write('Hyperprompt CLI (mock)\n  editor-rpc\n');
	process.exit(0);
}

if (!args.includes('editor-rpc')) {
	process.stderr.write('Unsupported command\n');
	process.exit(1);
}

let buffer = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
	buffer += chunk;
	let index = buffer.indexOf('\n');
	while (index >= 0) {
		const line = buffer.slice(0, index).trim();
		buffer = buffer.slice(index + 1);
		if (line.length > 0) {
			handleLine(line);
		}
		index = buffer.indexOf('\n');
	}
});

process.stdin.on('end', () => {
	if (buffer.trim().length > 0) {
		handleLine(buffer.trim());
	}
});

const handleLine = (line) => {
	let request;
	try {
		request = JSON.parse(line);
	} catch (error) {
		return;
	}

	logRequest({ method: request.method, params: request.params ?? null });

	switch (request.method) {
		case 'editor.compile': {
			const entryFile = request.params?.entryFile ?? '';
			if (String(entryFile).includes('large.hc')) {
				const diagnostics = Array.from({ length: 50 }, (_, index) => ({
					code: 'W001',
					severity: 'warning',
					message: `Synthetic warning ${index + 1}`,
					range: {
						start: { line: 1, column: 1 },
						end: { line: 1, column: 2 }
					}
				}));
				return writeResponse({
					jsonrpc: '2.0',
					id: request.id,
					result: {
						output: `${'# Large Output\\n'.repeat(200)}`,
						diagnostics,
						hasErrors: false
					}
				});
			}
			if (String(entryFile).includes('broken.hc')) {
				return writeResponse({
					jsonrpc: '2.0',
					id: request.id,
					result: {
						output: '',
						diagnostics: [
							{
								code: 'E001',
								severity: 'error',
								message: 'Broken file',
								range: {
									start: { line: 1, column: 1 },
									end: { line: 1, column: 2 }
								}
							}
						],
						hasErrors: true
					}
				});
			}
			return writeResponse({
				jsonrpc: '2.0',
				id: request.id,
				result: {
					output: '# Preview\n',
					diagnostics: [],
					hasErrors: false
				}
			});
		}
		case 'editor.linkAt': {
			const filePath = request.params?.filePath ?? '';
			return writeResponse({
				jsonrpc: '2.0',
				id: request.id,
				result: {
					literal: 'docs/readme.md',
					byteRangeStart: 2,
					byteRangeEnd: 16,
					lineRangeStart: 1,
					lineRangeEnd: 2,
					columnRangeStart: 3,
					columnRangeEnd: 17,
					referenceHint: 'fileReference',
					sourceFile: filePath
				}
			});
		}
		case 'editor.resolve': {
			const workspaceRoot = request.params?.workspaceRoot ?? '';
			const linkPath = request.params?.linkPath ?? '';
			return writeResponse({
				jsonrpc: '2.0',
				id: request.id,
				result: {
					type: 'markdownFile',
					path: path.join(workspaceRoot, linkPath)
				}
			});
		}
		case 'editor.indexProject': {
			return writeResponse({
				jsonrpc: '2.0',
				id: request.id,
				result: { files: [] }
			});
		}
		case 'editor.parse': {
			return writeResponse({
				jsonrpc: '2.0',
				id: request.id,
				result: {
					sourceFile: request.params?.filePath ?? '',
					linkSpans: [],
					hasDiagnostics: false
				}
			});
		}
		default:
			return writeResponse({
				jsonrpc: '2.0',
				id: request.id,
				error: { code: -32601, message: `Method not found: ${request.method}` }
			});
	}
};
