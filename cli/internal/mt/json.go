package mt

import "encoding/json"

func jsonUnmarshal(data json.RawMessage, v any) error {
	if len(data) == 0 {
		return nil
	}
	return json.Unmarshal(data, v)
}
