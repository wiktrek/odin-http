package main
// ! I WILL REFACTOR THIS CODE 
// ! I'm still learning odin + tcp/http
// TODO:
/*
*IMPORTANT:
	check if its a http request
	reformat the received string into a struct 
	make routing work
	separate into different files
	handle html files

	LESS IMPORTANT:
	file based routing
*/  
import "core:fmt"
import "core:net"
import "core:thread"
import "core:strings"
import "core:os"
// TODO: FIX THIS 
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
	// response := fmt.aprintf(
	// 	"http/1.1 200 ok\r\n" +
	// 	"content-type: text/html\r\n" +
	// 	"content-length: %d\r\n" +
	// 	"connection: close\r\n" +
	// 	"\r\n" +
	// 	"%s",
	// 	len(body),
	// 	body,
	// )
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
is_ctrl_d :: proc(bytes: []u8) -> bool {
	return len(bytes) == 1 && bytes[0] == 4
}

is_empty :: proc(bytes: []u8) -> bool {
	return(
		(len(bytes) == 2 && bytes[0] == '\r' && bytes[1] == '\n') ||
		(len(bytes) == 1 && bytes[0] == '\n') \
	)
}

is_telnet_ctrl_c :: proc(bytes: []u8) -> bool {
	return(
		(len(bytes) == 3 && bytes[0] == 255 && bytes[1] == 251 && bytes[2] == 6) ||
		(len(bytes) == 5 &&
				bytes[0] == 255 &&
				bytes[1] == 244 &&
				bytes[2] == 255 &&
				bytes[3] == 253 &&
				bytes[4] == 6) \
	)
}

handle_msg :: proc(sock: net.TCP_Socket) {
	buffer: [512]u8
	for {
		bytes_recv, err_recv := net.recv_tcp(sock, buffer[:])
		if err_recv != nil {
			fmt.println("Failed to receive data")
		}
		received := buffer[:bytes_recv]
		if len(received) == 0 ||
		   is_ctrl_d(received) ||
		   is_empty(received) ||
		   is_telnet_ctrl_c(received) {
			fmt.println("Disconnecting client")
			break
		}
		// TODO: REFORMAT THIS INTO A STRUCT
		fmt.printfln("Server received [ %d bytes ]: \n%s", len(received), received)
		// fmt.printfln("Server %s", received)

		req_struct := format_http_response(string(received))
		body : string
		if len(req_struct.path)>6 && req_struct.path[:6] == "/files"  {
			data, ok := os.read_entire_file(fmt.aprintf("pages/%s.html", req_struct.path[6:]), context.temp_allocator)
			if ok == nil {
				// fmt.printfln("FILE CONTENT: %s", data)
				body = string(data)
			} else {
				fmt.println("ERROR READING FILE", ok)
			}
		} else {
			data, ok := os.read_entire_file("pages/404.html", context.temp_allocator)
			if ok == nil {
				// fmt.printfln("FILE CONTENT: %s", data)
				body = string(data)
			} else {
				fmt.println("ERROR NO 404 FILE", ok)
				break
			}
			send_response(sock, MyResponse {
				"HTTP/1.1",
				404,
				"text/html",
				body
			})
			break
			// bytes_sent, err_send := net.send_tcp(sock, transmute([]u8)response)
			// if err_send != nil {
			// 	fmt.println("Failed to send data")
			// }
		}
		send_response(sock, MyResponse {
				"HTTP/1.1",
				200,
				"text/html",
				body
		})
		// response := fmt.aprintf(
		// 	"HTTP/1.1 200 OK\r\n" +
		// 	"Content-Type: text/html\r\n" +
		// 	"Content-Length: %d\r\n" +
		// 	"Connection: close\r\n" +
		// 	"\r\n" +
		// 	"%s",
		// 	len(body),
		// 	body,
		// )	
		// bytes_sent, err_send := net.send_tcp(sock, transmute([]u8)response)
		// if err_send != nil {
		// 	fmt.println("Failed to send data")
		// }
		// sent := received[:bytes_sent]
		// fmt.printfln("\n\nServer sent [ %d bytes ]: %s", len(sent), sent)
	}
	net.close(sock)
}

tcp_echo_server :: proc(ip: string, port: int) {
	local_addr, ok := net.parse_ip4_address(ip)
	if !ok {
		fmt.println("Failed to parse IP address")
		return
	}
	endpoint := net.Endpoint {
		address = local_addr,
		port    = port,
	}
	sock, err := net.listen_tcp(endpoint)
	if err != nil {
		fmt.println("Failed to listen on TCP")
		return
	}
	fmt.printfln("Listening on TCP: %s", net.endpoint_to_string(endpoint))
	for {
		cli, _, err_accept := net.accept_tcp(sock)
		if err_accept != nil {
			fmt.println("Failed to accept TCP connection")
			continue
		}
		thread.create_and_start_with_poly_data(cli, handle_msg)
	}
	net.close(sock)
	fmt.println("Closed socket")
}

main :: proc() {
	tcp_echo_server("127.0.0.1", 8080)
}
