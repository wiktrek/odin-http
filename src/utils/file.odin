package utils
import "core:os"
import "core:fmt"
FileError :: enum {
    No_dir,
    File_not_found,
}
read_file :: proc(path: string) -> (string , FileError){
    
    cur_dir, err := os.get_executable_directory(context.allocator);
    if err != nil {
        fmt.println("ERROR GETTING CURRENT DIR %s", err)
        return "", FileError.No_dir
    }
    full_path := fmt.aprintf("%s/%s",cur_dir,path)
    data, ok := os.read_entire_file(full_path, context.temp_allocator)
    if ok == nil {
        return string(data), nil
    } else {
        fmt.println("ERROR READING FILE", ok)
        return "", FileError.File_not_found,
    }
}
