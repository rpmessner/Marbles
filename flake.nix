{
  description = "Bidama Hajiki - A marble flicking game with Zig and Vulkan";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "bidama-hajiki";

          buildInputs = with pkgs; [
            # Zig - use nixpkgs version (or keep using asdf)
            zig

            # Vulkan
            vulkan-loader
            vulkan-headers
            vulkan-validation-layers
            vulkan-tools  # vulkaninfo, etc.

            # GLFW for windowing
            glfw

            # Shader compilation
            shaderc  # provides glslc

            # X11/Wayland for WSL2
            xorg.libX11
            xorg.libXrandr
            xorg.libXinerama
            xorg.libXcursor
            xorg.libXi
            wayland
            libxkbcommon

            # Build tools
            pkg-config
          ];

          # Environment variables for Vulkan
          VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";

          shellHook = ''
            echo ""
            echo "🎮 Bidama Hajiki dev environment"
            echo "   Zig:   $(zig version)"
            echo "   glslc: $(which glslc)"
            echo ""
          '';
        };
      }
    );
}
