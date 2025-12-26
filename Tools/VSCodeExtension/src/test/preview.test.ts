import * as assert from 'assert';
import { buildPreviewHtml, escapeHtml } from '../preview';

suite('Preview', () => {
	test('escapeHtml escapes special characters', () => {
		const value = '<script>"test" & test</script>';
		assert.strictEqual(
			escapeHtml(value),
			'&lt;script&gt;&quot;test&quot; &amp; test&lt;/script&gt;'
		);
	});

	test('buildPreviewHtml includes content', () => {
		const html = buildPreviewHtml('# Title');
		assert.ok(html.includes('# Title'));
		assert.ok(html.includes('<pre>'));
		assert.ok(html.includes('Hyperprompt Preview'));
	});
});
