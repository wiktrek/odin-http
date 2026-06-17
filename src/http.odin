package main
import "core:fmt"
import "core:net"
import "core:thread"
import "core:strings"
HttpResponse :: struct {
	method: string,
	url: string,
	type: string,
	host: string,
	user_agent: string,
	accept: string,
	accept_language: string,
	referer: string,
	path: string,
}
MyResponse :: struct {
	Protocol: string,
	Code: int,
	Content_type: string,
	body: string,
}
code_text :: proc(code: int) -> string {
	// TODO: TRY CONVERTING INTO ENUM
	switch code {
		case 200:
			return "OK"
		case 404:
			return "Not Found"
	}
	fmt.printfln("ERROR: RETURNED CODE NOT FOUND")
	return "ERROR"
}
send_response :: proc(sock: net.TCP_Socket, r: MyResponse) {
	response := fmt.aprintf(
		"%s %d %s\r\n" +
		"content-type: %s\r\n" +
		"content-length: %d\r\n" +
		"connection: close\r\n" + 
		"\r\n" + 
		"%s",
		r.Protocol, r.Code, code_text(r.Code),r.Content_type, len(r.body), r.body
	)
	bytes_sent, err_send := net.send_tcp(sock, transmute([]u8)response)
	if err_send != nil {
		fmt.println("failed to send data")
	}
}
format_http_response :: proc(str: string) -> HttpResponse {
	r : HttpResponse
	i := 0
    parts := strings.split(str, "\r\n")
	// fmt.println("PARTS: \n")
    for part in parts {
        fmt.println(part)
		if len(part) > 0 {
			if part[0] == 'G' && part[1] == 'E' {
				r.path = strings.split(part, " ")[1];
				// fmt.printfln("\n\n\nPATH: %s\n\n\n",r.path)
        	}  
		}
	}
	return r
}