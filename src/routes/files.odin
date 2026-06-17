package routes
import "core:os"
import "core:fmt"
import "../utils"
files_route :: proc(file_name: string) -> (string, utils.FileError) {
    body, ok := utils.read_file(fmt.aprintf("src/pages/%s.html", file_name));
    if ok != nil {
        return "", ok
    }
    return body, nil
}