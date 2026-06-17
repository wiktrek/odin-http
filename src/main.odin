package main
// ! I WILL REFACTOR THIS CODE 
// ! I'm still learning odin + tcp/http
// TODO:
/*
*IMPORTANT:
	! READ THE HTTP STANDARD TO UNDERSTAND HOW TO HANDLE THINGS ( POSSIBLE REQUESTS/RESPONSES)
	! separate into different files
	check if its a http request
	reformat the received string into a struct 
	make routing work
	
	// handle html files

	LESS IMPORTANT:
	file based routing
*/  
import "core:fmt"
import "core:net"
import "core:thread"
import "core:strings"
import "core:os"
import "routes"
import "utils"
// TODO: FIX THIS 

handle_msg :: proc(sock: net.TCP_Socket) {
	buffer: [512]u8
	for {
		bytes_recv, err_recv := net.recv_tcp(sock, buffer[:])
		if err_recv != nil {
			fmt.println("Failed to receive data")
		}
		received := buffer[:bytes_recv]
		// TODO: REFORMAT THIS INTO A STRUCT
		fmt.printfln("Server received [ %d bytes ]: \n%s", len(received), received)
		// fmt.printfln("Server %s", received)

		req_struct := format_http_response(string(received))
		body : string
		if len(req_struct.path)>6 && req_struct.path[:6] == "/files"  {
			d, err := routes.files_route(req_struct.path[7:])
			if err != nil {
				break
			}
			body = d
		} else {
			data, ok := os.read_entire_file("/src/pages/404.html", context.temp_allocator)
			if ok == nil {
				// fmt.printfln("FILE CONTENT: %s", data)
				body = string(data)
			} else {
				fmt.println("ERROR 404 NO FILE", ok)
				break
			}
			send_response(sock, MyResponse {
				"HTTP/1.1",
				404,
				"text/html",
				body
			})
			break
		}
		send_response(sock, MyResponse {
				"HTTP/1.1",
				200,
				"text/html",
				body
		})
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
