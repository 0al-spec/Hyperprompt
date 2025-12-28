import * as assert from 'assert';
import { normalizeSeverity, toZeroBasedPosition, toZeroBasedRange } from '../diagnostics';

suite('Diagnostics', () => {
	test('normalizeSeverity defaults to error', () => {
		assert.strictEqual(normalizeSeverity('warning'), 'warning');
		assert.strictEqual(normalizeSeverity('info'), 'info');
		assert.strictEqual(normalizeSeverity('hint'), 'hint');
		assert.strictEqual(normalizeSeverity('unknown'), 'error');
		assert.strictEqual(normalizeSeverity(undefined), 'error');
	});

	test('toZeroBasedPosition converts 1-based to 0-based', () => {
		const position = toZeroBasedPosition({ line: 3, column: 5 });
		assert.deepStrictEqual(position, { line: 2, character: 4 });
	});

	test('toZeroBasedRange converts ranges', () => {
		const range = toZeroBasedRange({
			start: { line: 1, column: 1 },
			end: { line: 2, column: 3 }
		});
		assert.deepStrictEqual(range, {
			start: { line: 0, character: 0 },
			end: { line: 1, character: 2 }
		});
	});
});
