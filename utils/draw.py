import sys
import argparse
import numpy as np
from xml.dom.minidom import parse, parseString, Node
from lxml import etree
from shutil import copyfile

pole_direction = {('x', -1): 'WEST', ('x', 1): 'EAST', ('z', -1): 'NORTH', ('z', 1): 'SOUTH'}


def remove_blanks(node):
    for x in node.childNodes:
        if x.nodeType == Node.TEXT_NODE:
            if x.nodeValue:
                x.nodeValue = x.nodeValue.strip()
        elif x.nodeType == Node.ELEMENT_NODE:
            remove_blanks(x)


def section_header(section_name, end):
    return "<!-- {}{} -->\n".format('' if not end else '/', section_name)


def block(x, y, z, direction, bl_type, variant=''):
    return "<DrawBlock x=\"{}\" y=\"{}\" z=\"{}\" face=\"{}\" type=\"{}\"{}/>\n".format(x, y, z, direction, bl_type,
                ' variant=\"{}\"'.format(variant) if variant else variant)


def cuboid(x1, y1, z1, x2, y2, z2, bl_type, direction='', variant=''):
    return "<DrawCuboid x1=\"{}\" y1=\"{}\" z1=\"{}\" x2=\"{}\" y2=\"{}\" z2=\"{}\" type=\"{}\"{}{}/>\n"\
        .format(x1, y1, z1, x2, y2, z2, bl_type,
                ' face=\"{}\"'.format(direction) if direction else direction,
                ' variant=\"{}\"'.format(variant) if variant else variant)


def line(x1, y1, z1, x2, y2, z2, bl_type):
    return "<DrawLine x1=\"{}\" y1=\"{}\" z1=\"{}\" x2=\"{}\" y2=\"{}\" z2=\"{}\" type=\"{}\"/>\n".format(x1, y1, z1, x2, y2, z2, bl_type)


def draw_room(boundaries):
    draw_str = ''
    draw_str += section_header('STRUCTURE', False)
    draw_str += cuboid(*boundaries, bl_type='stone')
    air_boundaries = np.append(boundaries[0:3] + 1, boundaries[3:6] - 1)
    draw_str += cuboid(*air_boundaries, bl_type='air')
    ceiling_boudaries = np.copy(boundaries)
    ceiling_boudaries[1] = ceiling_boudaries[4]
    draw_str += cuboid(*ceiling_boudaries, bl_type='glass')
    floor_boundaries = np.copy(boundaries)
    floor_boundaries[4] = floor_boundaries[1]
    draw_str += cuboid(*floor_boundaries, bl_type='planks')
    draw_str += section_header('STRUCTURE', True)
    return draw_str

def draw_decoration(boundaries):
    draw_str = ''
    draw_str += draw_south_wall(boundaries)
    draw_str += draw_north_wall(boundaries)
    draw_str += draw_west_wall(boundaries)
    draw_str += draw_east_wall(boundaries)

    return draw_str

def corner2square(corner, offset):
    return np.append(corner, corner + offset)

def corner2cuboid(corner, offset, type, direction='', variant=''):
    return cuboid(*(corner2square(corner, offset)), bl_type=type, direction=direction, variant=variant)

def draw_lamp(base_x, base_y, base_z):
    draw_str = ''
    draw_str += block(base_x, base_y, base_z, 'UP', 'log', 'spruce')
    draw_str += block(base_x, base_y + 1, base_z, 'UP', 'dark_oak_fence')
    draw_str += block(base_x, base_y + 2, base_z, 'UP', 'stone_slab')
    return draw_str

def draw_bed_south(base_x, base_y, base_z):
    draw_str = ''
    draw_str += block(base_x, base_y, base_z, 'SOUTH', 'bed', 'foot')
    draw_str += block(base_x, base_y, base_z + 1, 'SOUTH', 'bed', 'head')
    return draw_str

def draw_banners(x, y, z):
    draw_str = ''
    draw_str += block(x, y, z, 'NORTH', 'wall_banner')
    draw_str += block(x + 1, y, z, 'NORTH', 'wall_banner')
    return draw_str


def add_bed_decor(corner):
    draw_str = ''
    draw_str += corner2cuboid(corner, [5, 3, 0], 'bookshelf')
    draw_str += corner2cuboid(corner + [0, 0, 0], [5, 1, 0], 'air')
    draw_str += corner2cuboid(corner + [2, 2, 0], [1, 0, 0], 'air')
    draw_str += corner2cuboid(corner + [2, 0, 0], [1, 0, 0], 'planks', variant='dark_oak')
    draw_str += draw_bed_south(*(corner + [2, 0, -2]))
    draw_str += draw_bed_south(*(corner + [3, 0, -2]))
    draw_str += corner2cuboid(corner + [2, 0, -3], [1, 0 , 0], 'wooden_slab', variant='dark_oak')
    draw_str += draw_lamp(*(corner + [1, 0, 0]))
    draw_str += draw_lamp(*(corner + [4, 0, 0]))
    draw_str += draw_banners(*(corner + [2, 2, 0]))
    draw_str += corner2cuboid(corner + [-2, 0, 0], [1, 0, 0], 'chest', 'SOUTH')
    draw_str += corner2cuboid(corner + [-2, 1, 1], [1, 1, 0], 'glass_pane')
    draw_str += block(corner[0] + 6, corner[1], corner[2] - 1, 'WEST', 'quartz_stairs')
    draw_str += block(corner[0] + 7, corner[1], corner[2] - 1, 'EAST', 'quartz_stairs')
    draw_str += corner2cuboid(corner + [6, 0, 0], [1, 0, 0], 'quartz_block')
    draw_str += corner2cuboid(corner + [6, 1, 1], [1, 1, 0], 'glass_pane')
    return draw_str


def draw_south_wall(boundaries):
    workarea_offset = np.array([3, 1, 0, 0, 0, -1])
    workarea = np.array(boundaries + workarea_offset)
    workarea[2] = workarea[5]
    corner = np.array(workarea[0:3])
    draw_str = ''
    draw_str += add_bed_decor(corner)
    draw_str += block(corner[0] + 2, corner[1] + 1, corner[2], 'SOUTH', 'flower_pot', variant='poppy')
    return draw_str


def draw_north_wall(boundaries):
    workarea_offset = np.array([4, 1, 1, 0, 0, 0])
    workarea = np.array(boundaries + workarea_offset)
    corner = np.array(workarea[0:3])
    draw_str = ''
    # draw_str += block(corner[0], corner[1], corner[2], 'SOUTH', 'flower_pot', variant='poppy')
    draw_str += corner2cuboid(corner + [0, 0, 0], [1, 1, 1], 'log', variant='spruce')
    draw_str += corner2cuboid(corner + [0, 0, 2], [1, 1, 0], 'wall_sign', 'SOUTH')
    draw_str += corner2cuboid(corner + [2, 0, 0], [2, 0, 1], 'stone', 'SOUTH', 'smooth_andesite')
    draw_str += block(corner[0] + 3, corner[1], corner[2] + 1, 'SOUTH', 'stone_stairs', 'bottom')
    draw_str += block(corner[0] + 3, corner[1] + 1, corner[2], 'UP_Z', 'lever')
    draw_str += corner2cuboid(corner + [2, 1, -1], [2, 1, 0], 'glass_pane')
    draw_str += corner2cuboid(corner + [5, 0, 0], [2, 2, 1], 'hay_block', 'UP')
    draw_str += corner2cuboid(corner + [5, 0, 1], [1, 1, 0], 'furnace', 'SOUTH')
    return draw_str

def draw_west_wall(boundaries):
    workarea_offset = np.array([1, 1, 1, 0, 0, 0])
    workarea = np.array(boundaries + workarea_offset)
    corner = np.array(workarea[0:3])
    draw_str = ''
    draw_str += corner2cuboid(corner, [2, 2, 3], 'hay_block', 'UP')
    draw_str += corner2cuboid(corner + [1, 0, 1], [1, 2, 2], 'air')
    draw_str += corner2cuboid(corner + [1, 0, 1], [0, 1, 1], 'coal_ore')
    draw_str += corner2cuboid(corner + [-1, 1, 4], [0, 1, 2], 'glass_pane')
    draw_str += corner2cuboid(corner + [-1, 1, 9], [0, 1, 1], 'glass_pane')
    return draw_str

def draw_east_wall(boundaries):
    workarea_offset = np.array([0, 1, 5, -1, 0, 0])
    workarea = np.array(boundaries + workarea_offset)
    workarea[0] = workarea[3]
    corner = np.array(workarea[0:3])
    draw_str = ''
    draw_str += block(corner[0], corner[1], corner[2], 'NORTH', 'dark_oak_stairs')
    draw_str += block(corner[0], corner[1], corner[2] + 1, 'NORTH', 'dark_oak_fence')
    draw_str += block(corner[0], corner[1] + 1, corner[2] + 1, 'UP', 'stone_pressure_plate')
    draw_str += block(corner[0], corner[1], corner[2] + 2, 'SOUTH', 'dark_oak_stairs')
    draw_str += corner2cuboid(corner + [1, 1, 0], [0, 1, 2], 'glass_pane')
    return draw_str


def draw_light(boundaries):
    draw_str = ''
    draw_str += section_header('LIGHTS', False)
    # Lights across the walls
    light_height = boundaries[1] + 3
    for x in boundaries[[0,3]]:
        z_range = np.arange(boundaries[2] + 2, boundaries[5] - 1)
        window_z = z_range[z_range % 5 == 0]
        torch_z = z_range[(z_range != 0) & (z_range % 2 == 0)]
        for z in torch_z:
            if x < 0:
                draw_str += block(x + 1, light_height, z, 'EAST', 'torch')
            else:
                draw_str += block(x - 1, light_height, z, 'WEST', 'torch')
        for z in window_z:
            if z - 1 <= boundaries[2] + 1 or z + 1 >= boundaries[5] - 1:
                draw_str += cuboid(x, light_height - 1, z, x, light_height, z, 'glass')
            else:
                draw_str += cuboid(x, light_height - 1, z - 1, x, light_height, z + 1, 'glass')
    for z in boundaries[[2, 5]]:
        x_range = np.arange(boundaries[0] + 2, boundaries[3] - 1)
        window_x = x_range[x_range % 5 == 0]
        torch_x = x_range[(x_range != 0) & (x_range % 2 == 0)]
        for x in torch_x:
            if z < 0:
                draw_str += block(x, light_height, z + 1, 'SOUTH', 'torch')
            else:
                draw_str += block(x, light_height, z - 1, 'NORTH', 'torch')
        for x in window_x:
            if x - 1 <= boundaries[0] + 1 or x + 1 >= boundaries[3] - 1:
                draw_str += cuboid(x, light_height - 1, z, x, light_height, z, 'glass')
            else:
                draw_str += cuboid(x - 1, light_height - 1, z, x + 1, light_height, z, 'glass')

    # Lights on middle pole
    pole_middle = np.array([np.mean(boundaries[[0, 3]]).astype('int16'), np.mean(boundaries[[2, 5]]).astype('int16')])
    for offset in [-1, 1]:
        draw_str += block(pole_middle[0] + offset, light_height, pole_middle[1], pole_direction['x', offset], 'torch')
        draw_str += block(pole_middle[0], light_height, pole_middle[1] + offset, pole_direction['z', offset], 'torch')
    draw_str += section_header('LIGHTS', True)
    return draw_str


if __name__ == "__main__":
    # Default world: python draw.py -7 226 -7 7 231 7 | xclip -selection clipboard

    parser = argparse.ArgumentParser(description='Create Minecraft world.')
    parser.add_argument('coords', action='store', nargs=6, type=int, metavar='COORDS', help='Coordinates of boundaries of house.')
    parser.add_argument('-f', '--file', action='store', dest='file', required=False, metavar='FILE', help='File to modify')
    # boundaries = [x_low, y_low, z_low, x_high, y_high, z_high]
    args = vars(parser.parse_args())
    boundaries = np.array(args['coords'])
    output_file = args['file']
    draw_str = ''
    draw_str += draw_room(boundaries)
    draw_str += draw_decoration(boundaries)
    # draw_str += draw_light(boundaries)

    if output_file:
        # Export as XML
        draw_dom = parseString('<DrawingDecorator>\n' + draw_str + '</DrawingDecorator>')
        file_dom = parse(output_file)

        # Replace old DrawingDecorator with new
        drawing_ele = file_dom.getElementsByTagName('DrawingDecorator')[0]
        drawing_ele.childNodes = draw_dom.childNodes[0].childNodes

        remove_blanks(file_dom)
        file_dom.normalize()
        # First backup existing file, then write XML to file
        copyfile(output_file, output_file + '.bak')
        with open(output_file, 'w') as of:
            file_dom.writexml(of, addindent='  ', newl='\n')
    else:
        print draw_str
