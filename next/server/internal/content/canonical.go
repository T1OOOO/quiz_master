package content

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"sort"
	"strings"
	"unicode"
	"unicode/utf8"

	"golang.org/x/text/cases"
	"golang.org/x/text/unicode/norm"
)

// NormalizeText matches the P04 Python reference, including its four additional
// Unicode information separators U+001C..U+001F in str.split's whitespace set.
func NormalizeText(s string) string {
	// Unicode default folding keeps Cherokee uppercase for stability. x/text
	// v0.34.0 lowers uppercase Cherokee; correct that documented exception.
	folded := strings.Map(func(r rune) rune {
		if r >= 0xab70 && r <= 0xabbf || r >= 0x13f8 && r <= 0x13fd {
			return unicode.ToUpper(r)
		}
		return r
	}, cases.Fold().String(norm.NFC.String(s)))
	return strings.Join(strings.FieldsFunc(folded, func(r rune) bool { return unicode.IsSpace(r) || r >= 0x1c && r <= 0x1f }), " ")
}

// decodeJSON rejects ambiguous duplicate object keys, malformed UTF-8 and trailing
// values before either the legacy mapper or the maintained schema validator runs.
func decodeJSON(b []byte, path string) (any, error) {
	if !utf8.Valid(b) {
		return nil, &Error{"invalid_json", path}
	}
	d := json.NewDecoder(bytes.NewReader(b))
	d.UseNumber()
	v, e := jsonValue(d, path, 0)
	if e != nil {
		return nil, e
	}
	if _, e = d.Token(); e != io.EOF {
		return nil, &Error{"trailing_json", path}
	}
	return v, nil
}
func jsonValue(d *json.Decoder, path string, depth int) (any, error) {
	if depth > 128 {
		return nil, &Error{"invalid_json", path}
	}
	t, e := d.Token()
	if e != nil {
		return nil, &Error{"invalid_json", path}
	}
	delim, ok := t.(json.Delim)
	if !ok {
		return t, nil
	}
	switch delim {
	case '{':
		m := map[string]any{}
		for d.More() {
			k, e := d.Token()
			if e != nil {
				return nil, &Error{"invalid_json", path}
			}
			key, ok := k.(string)
			if !ok {
				return nil, &Error{"invalid_json", path}
			}
			if _, ok = m[key]; ok {
				return nil, &Error{"duplicate_key", path}
			}
			v, e := jsonValue(d, path, depth+1)
			if e != nil {
				return nil, e
			}
			m[key] = v
		}
		if t, e = d.Token(); e != nil || t != json.Delim('}') {
			return nil, &Error{"invalid_json", path}
		}
		return m, nil
	case '[':
		a := []any{}
		for d.More() {
			v, e := jsonValue(d, path, depth+1)
			if e != nil {
				return nil, e
			}
			a = append(a, v)
		}
		if t, e = d.Token(); e != nil || t != json.Delim(']') {
			return nil, &Error{"invalid_json", path}
		}
		return a, nil
	default:
		return nil, &Error{"invalid_json", path}
	}
}

// Canonical uses sorted object keys, compact JSON and literal non-ASCII runes.
// Contract numeric fields are integers; generic number inputs retain their JSON
// spelling. This is P04 canonical JSON, not an RFC 8785 number canonicalizer.
func Canonical(v any) ([]byte, error) {
	b, e := json.Marshal(v)
	if e != nil {
		return nil, e
	}
	dec := json.NewDecoder(bytes.NewReader(b))
	dec.UseNumber()
	var value any
	if e = dec.Decode(&value); e != nil {
		return nil, e
	}
	var out bytes.Buffer
	canonicalValue(&out, value)
	return out.Bytes(), nil
}
func canonicalString(out *bytes.Buffer, s string) {
	out.WriteByte('"')
	for _, r := range s {
		switch r {
		case '"', '\\':
			out.WriteByte('\\')
			out.WriteRune(r)
		case '\b':
			out.WriteString(`\b`)
		case '\f':
			out.WriteString(`\f`)
		case '\n':
			out.WriteString(`\n`)
		case '\r':
			out.WriteString(`\r`)
		case '\t':
			out.WriteString(`\t`)
		default:
			if r < 0x20 {
				fmt.Fprintf(out, `\u%04x`, r)
			} else {
				out.WriteRune(r)
			}
		}
	}
	out.WriteByte('"')
}
func canonicalValue(out *bytes.Buffer, v any) {
	switch x := v.(type) {
	case map[string]any:
		keys := make([]string, 0, len(x))
		for k := range x {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		out.WriteByte('{')
		for i, k := range keys {
			if i > 0 {
				out.WriteByte(',')
			}
			canonicalString(out, k)
			out.WriteByte(':')
			canonicalValue(out, x[k])
		}
		out.WriteByte('}')
	case []any:
		out.WriteByte('[')
		for i, item := range x {
			if i > 0 {
				out.WriteByte(',')
			}
			canonicalValue(out, item)
		}
		out.WriteByte(']')
	case string:
		canonicalString(out, x)
	case json.Number:
		out.WriteString(x.String())
	case bool:
		if x {
			out.WriteString("true")
		} else {
			out.WriteString("false")
		}
	case nil:
		out.WriteString("null")
	}
}
func hashBytes(b []byte) string { h := sha256.Sum256(b); return hex.EncodeToString(h[:]) }
func sum(v any) string {
	b, e := Canonical(v)
	if e != nil {
		return ""
	}
	return hashBytes(b)
}
func hashWithout(v any, key string) string {
	b, e := json.Marshal(v)
	if e != nil {
		return ""
	}
	var obj map[string]any
	d := json.NewDecoder(bytes.NewReader(b))
	d.UseNumber()
	if d.Decode(&obj) != nil {
		return ""
	}
	delete(obj, key)
	return sum(obj)
}

// Rehash is explicit: validation/build never silently repair stale revisions.
func Rehash(d *Draft) {
	for i := range d.Questions {
		d.Questions[i].Revision.SHA256 = hashWithout(d.Questions[i], "revision")
	}
	d.Revision.SHA256 = hashWithout(*d, "revision")
}
