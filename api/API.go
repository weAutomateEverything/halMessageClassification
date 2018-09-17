package api

/*
TextEvent Request Message
 */
type TextEvent struct {
	Chat    int64  `json:"chat"`
	Message string `json:"message"`
	MessageID string `json:"message_id"`
}
