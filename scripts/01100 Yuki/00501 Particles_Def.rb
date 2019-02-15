module Yuki
  module Particles
    # The particle data
    Data = []
    # Particles for tag 0
    Data[0] = {}
    # Particles for tag 1
    Data[1] = {}
    # The empty actions
    EMPTY = { max_counter: 1, loop: false, data: [] }

    # Grass particle
    Data[0][1] = {
      enter: {
        max_counter: 7,
        data: [
          { file: 'herbe', rect: [0, 0, 16, 16], zoom: 1, position: :grass_pos, se_player_play: 'audio/particles/grass01_a' },
          { wait: 3 },
          { rect: [0, 16, 16, 16] },
          { wait: 3 },
          { rect: [0, 32, 16, 16] },
          { wait: 3 },
          { rect: [0, 48, 16, 16] }
        ],
        loop: false
      },
      stay: {
        max_counter: 1,
        data: [
          { file: 'herbe', zoom: 1, position: :grass_pos, rect: [0, 48, 16, 16] }
        ],
        loop: false
      },
      leave: {
        max_counter: 1,
        data: [],
        loop: false
      }
    }

    # Taller grass particle
    Data[0][2] = {
      enter: {
        max_counter: 8,
        data: [
          nil, nil, nil,
          { file: 'hauteherbe', zoom: 1, position: :grass_pos, se_player_play: 'audio/particles/grass01_b' }
        ],
        loop: false
      },
      stay: {
        max_counter: 1,
        data: [
          { file: 'hauteherbe', zoom: 1, position: :grass_pos }
        ],
        loop: false
      },
      leave: {
        max_counter: 1,
        data: [],
        loop: false
      }
    }

    # Exclamation emotion particle
    Data[0][:exclamation] = {
      enter: {
        max_counter: 36,
        data: [
          { file: 'emotions', rect: [0, 0, 16, 16], zoom: 1, position: :center_pos, add_z: -1, oy_offset: 0 },
          nil, {oy_offset: 2},
          nil, {oy_offset: 4},
          nil, {oy_offset: 8},
          nil, {oy_offset: 12},
          nil, {oy_offset: 16, add_z: 64},
          nil, {oy_offset: 20},
          nil, {oy_offset: 24},
          nil, {oy_offset: 20}
        ],
        loop: false
      },
      stay: {
        max_counter: 2,
        data: [
          { state: :leave }
        ],
        loop: false
      },
      leave: Data[0][2][:leave]
    }

    # All the existing emotions
    emotion_str = <<-EOEMOTION
    Data[0][:%<name>s] = {
      enter: {
        max_counter: 60,
        data: [
          { file: "emotions", rect: [%<x>d, %<y>d, 16, 16], zoom: 1, position: :center_pos, oy_offset: 10 },
          *Array.new(28),
          { rect: [%<target>d, %<y>d, 16, 16] }
        ],
        loop: false
      },
      stay: Data[0][:exclamation][:stay],
      leave: Data[0][2][:leave]
    }
    EOEMOTION
    module_eval(format(emotion_str, name: 'poison', y: 0, x: 32, target: 48))
    module_eval(format(emotion_str, name: 'exclamation2', y: 16, x: 0, target: 16))
    module_eval(format(emotion_str, name: 'interrogation', y: 32, x: 0, target: 16))
    module_eval(format(emotion_str, name: 'music', y: 16, x: 32, target: 48))
    module_eval(format(emotion_str, name: 'love', y: 32, x: 32, target: 48))
    module_eval(format(emotion_str, name: 'joy', y: 0, x: 64, target: 80))
    module_eval(format(emotion_str, name: 'sad', y: 16, x: 64, target: 80))
    module_eval(format(emotion_str, name: 'happy', y: 32, x: 64, target: 80))
    module_eval(format(emotion_str, name: 'angry', y: 0, x: 96, target: 112))
    module_eval(format(emotion_str, name: 'sulk', y: 16, x: 96, target: 112))
    module_eval(format(emotion_str, name: 'nocomment', y: 32, x: 96, target: 112))

    # The dust when the player jump
    Data[0][:dust] = {
      enter: {
        max_counter: 7,
        loop: false,
        data: [
          { file: 'dust', rect: [0, 0, 16, 8], zoom: 1, position: :center_pos, add_z: 2 },
          { wait: 5 }, { rect: [16, 0, 16, 8], se_player_play: 'audio/particles/jump' },
          { wait: 5 }, { rect: [32, 0, 16, 8] },
          { wait: 5 }, { rect: [48, 0, 1, 1] }
        ]
      },
      stay: EMPTY,
      leave: EMPTY
    }

    # Fading of a step on the ground
    TRACK_OPACITY_FADING = [{ wait: 17 }, { opacity: 115 }, { wait: 17 }, { opacity: 100 }, { wait: 17 }, { opacity: 85 }, { wait: 17 }, { opacity: 70 }, { wait: 17 }, { opacity: 55 }, { wait: 17 }, { opacity: 40 }, { wait: 17 }, { opacity: 25 }, { wait: 17 }, { opacity: 10 }, { wait: 17 }, { opacity: 0 }]
    # Footprint on sand tile (going down)
    Data[0][:sand_d] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 19,
        loop: false,
        data: [
          { file: 'floor_print', rect: [0, 0, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 125 },
          *TRACK_OPACITY_FADING
        ]
      }
    }
    # Footprint on sand tile (going to the left)
    Data[0][:sand_l] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 19,
        loop: false,
        data: [
          { file: 'floor_print', rect: [16, 0, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 125 },
          *TRACK_OPACITY_FADING
        ]
      }
    }
    # Footprint on sand tile (going to the right)
    Data[0][:sand_r] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 19,
        loop: false,
        data: [
          { file: 'floor_print', rect: [32, 0, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 125 },
          *TRACK_OPACITY_FADING
        ]
      }
    }
    # Footprint on sand tile (going up)
    Data[0][:sand_u] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 19,
        loop: false,
        data: [
          { file: 'floor_print', rect: [48, 0, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 125 },
          *TRACK_OPACITY_FADING
        ]
      }
    }
    # Circle shown when we surf on a pond tile
    Data[0][:pond] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 13,
        loop: false,
        data: [
          { file: 'surf_print', rect: [0, 0, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 255 },
          { wait: 8 }, { rect: [16, 0, 16, 16] },
          { wait: 8 }, { rect: [32, 0, 16, 16] },
          { wait: 8 }, { rect: [48, 0, 16, 16] },
          { wait: 8 }, { rect: [64, 0, 16, 16] },
          { wait: 8 }, { rect: [80, 0, 16, 16] },
          { wait: 8 }, { rect: [96, 0, 16, 16] }
        ]
      }
    }
    # Fading of a step on the snow
    TRACK_SNOW_OPACITY_FADING = [
      { wait: 9 }, { opacity: 240 }, { wait: 9 }, { opacity: 225 }, { wait: 9 }, { opacity: 210 }, { wait: 9 }, { opacity: 195 }, { wait: 9 }, { opacity: 180 }, { wait: 9 },
      { opacity: 165 }, { wait: 9 }, { opacity: 150 }, { wait: 9 }, { opacity: 135 }, { wait: 9 }, { opacity: 120 }, { wait: 9 }, { opacity: 105 }, { wait: 9 }, { opacity: 90 },
      { wait: 9 }, { opacity: 75 }, { wait: 9 }, { opacity: 60 }, { wait: 9 }, { opacity: 45 }, { wait: 9 }, { opacity: 30 }, { wait: 9 }, { opacity: 15 }, { wait: 9 }, { opacity: 0 }
    ]
    # Snow footprint when going down
    Data[0][:snow_d] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 35,
        loop: false,
        data: [
          { file: 'floor_print', rect: [0, 16, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 250 },
          *TRACK_SNOW_OPACITY_FADING
        ]
      }
    }
    # Snow footprint when going to the left
    Data[0][:snow_l] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 35,
        loop: false,
        data: [
          { file: 'floor_print', rect: [16, 16, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 125 },
          *TRACK_SNOW_OPACITY_FADING
        ]
      }
    }
    # Snow footprint when going to the right
    Data[0][:snow_r] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 35,
        loop: false,
        data: [
          { file: 'floor_print', rect: [32, 16, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 250 },
          *TRACK_SNOW_OPACITY_FADING
        ]
      }
    }
    # Snow footprint when going up
    Data[0][:snow_u] = {
      enter: EMPTY,
      stay: EMPTY,
      leave: {
        max_counter: 35,
        loop: false,
        data: [
          { file: 'floor_print', rect: [48, 16, 16, 16], zoom: 1, add_z: -32, position: :center_pos, opacity: 125 },
          *TRACK_SNOW_OPACITY_FADING
        ]
      }
    }

    # Splash water particle (badly defined)
    Data[0][:splash_water] = {
      enter: {
        max_counter: 31,
        loop: false,
        data: [
          { file: 'eclaboussures', rect: [0, 0, 40, 7], zoom: 1, position: :center_pos, add_z: 32, ox_offset: -11, se_player_play: 'audio/particles/diving' },
          { wait: 4 }, { rect: [40, 0, 40, 7] },
          { wait: 4 }, { rect: [80, 0, 40, 7] },
          { wait: 4 }, { rect: [0, 0, 40, 7] },
          { wait: 4 }, { rect: [40, 0, 40, 7] },
          { wait: 4 }, { rect: [80, 0, 40, 7] },
          { wait: 4 }, { rect: [0, 0, 40, 7] },
          { wait: 4 }, { rect: [40, 0, 40, 7] },
          { wait: 4 }, { rect: [80, 0, 40, 7] },
          { wait: 4 }, { rect: [0, 0, 40, 7] },
          { wait: 4 }, { rect: [40, 0, 40, 7] },
          { wait: 4 }, { rect: [80, 0, 40, 7] },
          { wait: 4 }, { rect: [0, 0, 40, 7] },
          { wait: 4 }, { rect: [40, 0, 40, 7] },
          { wait: 4 }, { rect: [80, 0, 40, 7] },
          { wait: 4 }, { rect: [0, 0, 40, 7] }
        ]
      },
      stay: { max_counter: 1, loop: false, data: [{ state: :leave }] },
      leave: EMPTY
    }

    module_function

    # Function that find the data for a particle according to the terrain_tag & the particle tag
    # @note This function will try $game_variables[Var::PAR_DatID] & 0 as terrain_tag if the particle_tag wasn't found in the Hashes
    # @param terrain_tag [Integer] terrain_tag in which the event is
    # @param particle_tag [Integer, Symbol] identifier of the particle in the hash
    def find_particle(terrain_tag, particle_tag)
      Data.dig(terrain_tag, particle_tag) || Data.dig($game_variables[Var::PAR_DatID], particle_tag) || Data.dig(0, particle_tag)
    end
  end
end