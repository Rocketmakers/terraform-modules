package rmutils

func AllItemsTrue(b []bool) int {
	n := 0
	for _, v := range b {
			if v {
					n++
			}
	}
	return n
}