//
//  main.m
//  seek_usb_parser
//
//  Created by Ethan Arbuckle on 12/12/23.
//

#import <Foundation/Foundation.h>

#define FILE_PATH "/Users/ethanarbuckle/Desktop/seek_usbmon.txt"
#define COLOR_GREEN "\033[92m"
#define COLOR_ORANGE "\033[93m"
#define COLOR_BLUE "\033[94m"
#define COLOR_PURPLE "\033[95m"
#define COLOR_RESET "\033[0m"
#define COMMAND_MAP_SIZE 37
#define BUFFER_SIZE 4096

typedef struct {
    uint8_t code;
    const char *name;
} CommandMapEntry;

const CommandMapEntry command_map[COMMAND_MAP_SIZE] = {
    {53, "GET_ERROR_CODE"},
    {54, "READ_CHIP_ID"},
    {55, "TOGGLE_SHUTTER"},
    {56, "SET_SHUTTER_POLARITY"},
    {57, "GET_SHUTTER_POLARITY"},
    {58, "SET_BIT_DATA_OFFSET"},
    {59, "GET_BIT_DATA"},
    {60, "SET_OPERATION_MODE"},
    {61, "GET_OPERATION_MODE"},
    {62, "SET_IMAGE_PROCESSING_MODE"},
    {63, "GET_IMAGE_PROCESSING_MODE"},
    {64, "SET_DATA_PAGE"},
    {65, "GET_DATA_PAGE"},
    {66, "SET_CURRENT_COMMAND_ARRAY_SIZE"},
    {67, "SET_CURRENT_COMMAND_ARRAY"},
    {68, "GET_CURRENT_COMMAND_ARRAY"},
    {69, "SET_DEFAULT_COMMAND_ARRAY_SIZE"},
    {70, "SET_DEFAULT_COMMAND_ARRAY"},
    {71, "GET_DEFAULT_COMMAND_ARRAY"},
    {72, "SET_VDAC_ARRAY_OFFSET_AND_ITEMS"},
    {73, "SET_VDAC_ARRAY"},
    {74, "GET_VDAC_ARRAY"},
    {75, "SET_RDAC_ARRAY_OFFSET_AND_ITEMS"},
    {76, "SET_RDAC_ARRAY"},
    {77, "GET_RDAC_ARRAY"},
    {78, "GET_FIRMWARE_INFO"},
    {79, "UPLOAD_FIRMWARE_ROW_SIZE"},
    {80, "WRITE_MEMORY_DATA"},
    {81, "COMPLETE_MEMORY_WRITE"},
    {82, "BEGIN_MEMORY_WRITE"},
    {83, "START_GET_IMAGE_TRANSFER"},
    {84, "TARGET_PLATFORM"},
    {85, "SET_FIRMWARE_INFO_FEATURES"},
    {86, "SET_FACTORY_SETTINGS_FEATURES"},
    {87, "SET_FACTORY SETTINGS"},
    {88, "GET_FACTORY_SETTINGS"},
    {89, "RESET_DEVICE"},
};

void print_colored(const char *string, const char *color) {
    printf("%s%s", color, string);
}

const char *get_command_name(uint8_t command_value) {
    
    for (int i = 0; i < COMMAND_MAP_SIZE; ++i) {
        if (command_map[i].code == command_value) {
            return command_map[i].name;
        }
    }

    return "unknown command";
}

void parse_usbmon_line(const char *original_line) {
    
    char line[BUFFER_SIZE];
    strncpy(line, original_line, BUFFER_SIZE - 1);

    char *parts[16];
    char *context = NULL;
    char *tok = strtok_r(line, " ", &context);
    int part_index = 0;

    while (tok != NULL && part_index < 16) {
        parts[part_index++] = tok;
        tok = strtok_r(NULL, " ", &context);
    }

    if (part_index < 5) {
        return;
    }

    char *urb_status = parts[4];
    char *address = parts[3];
    int is_outgoing_direction = address[1] == 'o';
    const char *command_name;
    const char *color_code;

    if (*parts[2] == 'C' || (*parts[2] == 'S' && *urb_status != 's')) {

        command_name = "CTRL RESPONSE";
        color_code = is_outgoing_direction ? COLOR_ORANGE : COLOR_BLUE;
    }
    else if (*parts[2] == 'S' && *urb_status == 's') {
        
        int command_value = (int)strtol(parts[6], NULL, 16);
        command_name = get_command_name((uint8_t)command_value);
        color_code = COLOR_ORANGE;
    }
    else {
        command_name = "unknown command";
        color_code = COLOR_RESET;
    }

    printf("%s", color_code);
    printf("-----\n");
    printf("%s to %s\n", command_name, is_outgoing_direction ? "CAMERA" : "HOST");
    printf("-----\n");
    printf("  event name: %s\n", command_name);

    if (*parts[2] == 'S' && *urb_status == 's') {

        printf("  command value: %d / 0x%02X\n", (int)strtol(parts[6], NULL, 16), (int)strtol(parts[6], NULL, 16));
        printf("  data length: %d\n", (int)strtol(parts[9], NULL, 16));

        const char *data_part = strstr(original_line, " = ");
        if (data_part) {

            data_part += 3;

            printf("  data: ");
            for (int i = 0; i < 8 && *data_part && *data_part != '\n'; i += 2, data_part += 3) {
                printf("%c%c ", *(data_part), *(data_part + 1));
            }
            printf("\n");
        }
    }

    printf("%s\n", original_line);
    printf("-----\n%s\n", COLOR_RESET);
}

int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        
        FILE *file = fopen(FILE_PATH, "r");
        if (!file) {
            return 1;
        }

        char line[BUFFER_SIZE];
        while (fgets(line, sizeof(line), file)) {
            line[strcspn(line, "\n")] = 0;
            parse_usbmon_line(line);
        }

        fclose(file);
    }

    return 0;
}
