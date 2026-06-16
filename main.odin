package main

import "core:fmt"
AStruct :: struct {
	text: string
}
eenum :: enum {
	One,
	Two,
	Three,
}

main :: proc() {
	print("Hello world!")
	ee : eenum
	ee = .One
	switch ee {
		case .One:
			print("One");
			// fallthrough
		case .Two:
			print("Two")
		case .Three:
			print("Three")
	}

}

print :: proc(str: string) {
	fmt.println(str)
}