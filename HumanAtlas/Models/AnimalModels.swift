import Foundation

/// A whale species from the Whale Atlas field guide. Copy is based on the linked
/// NOAA Fisheries species profiles; geographic ranges describe typical
/// distribution, not live sightings.
struct WhaleSpecies: Identifiable {
    let slug: String
    let name: String
    let latin: String
    let type: String
    let length: String
    let diet: String
    let habitat: String
    let headline: String
    let description: String
    let fact: String
    let imageFile: String
    let places: [String]
    let whereTheyLive: String
    let movement: String
    let history: String
    let protection: String

    var id: String { slug }
    var suborder: String { type == "Baleen" ? "Mysticeti" : "Odontoceti" }
    var classification: String { "\(type.uppercased()) WHALE / \(suborder.uppercased())" }
    var noaaURL: URL { URL(string: "https://www.fisheries.noaa.gov/species/\(slug)")! }
}

enum WhaleCatalog {
    /// Body-surface parts drawn see-through so the organs inside stay visible.
    static let exteriorIds: Set<String> = ["Skin", "Flippers", "Flukes", "Dorsal"]

    static let parts: [BodySystem] = [
        BodySystem(id: "Skin", name: "Skin & blubber", colorHex: "#799daa", info: "The outer skin and underlying blubber form the body envelope. Blubber helps insulate the whale and stores energy."),
        BodySystem(id: "Flippers", name: "Pectoral flippers", colorHex: "#87aabb", info: "Paired forelimbs help steer and stabilize the whale. They contain bones homologous to the bones in a human arm and hand."),
        BodySystem(id: "Flukes", name: "Tail flukes", colorHex: "#87aabb", info: "Horizontal flukes move up and down to propel the whale. They are made of connective tissue rather than finger-like bones."),
        BodySystem(id: "Dorsal", name: "Dorsal fin / ridge", colorHex: "#87aabb", info: "The dorsal structure varies by species. Belugas have a ridge; orcas have a prominent fin."),
        BodySystem(id: "Brain", name: "Brain", colorHex: "#d7a8a2", info: "The brain processes sensory information and controls movement and other body functions."),
        BodySystem(id: "Heart", name: "Heart", colorHex: "#bb424c", info: "A four-chambered heart pumps blood through the lungs and the rest of the body."),
        BodySystem(id: "Lungs", name: "Lungs", colorHex: "#cb8e98", info: "Whales breathe air at the surface. Paired lungs sit toward the back of the chest, close to the spine."),
        BodySystem(id: "Liver", name: "Liver", colorHex: "#88433d", info: "The liver processes nutrients and supports metabolism. Its position here is a schematic guide."),
        BodySystem(id: "Stomach", name: "Stomach", colorHex: "#dca08d", info: "The stomach helps break down swallowed prey. Cetaceans have a multi-compartment stomach."),
        BodySystem(id: "Kidneys", name: "Kidneys", colorHex: "#a85650", info: "Paired, lobulated kidneys filter blood and help regulate water and salts."),
        BodySystem(id: "Intestines", name: "Intestines", colorHex: "#e1a592", info: "The intestines absorb nutrients and water and carry remaining material toward elimination."),
    ]

    static let all: [WhaleSpecies] = [
        WhaleSpecies(
            slug: "blue-whale", name: "Blue whale", latin: "Balaenoptera musculus", type: "Baleen",
            length: "Up to 33.5 m", diet: "Krill", habitat: "Outside the Arctic",
            headline: "The largest animal ever to live.",
            description: "A long, streamlined body moves through the open ocean. Instead of teeth, blue whales have baleen plates that strain tiny krill from seawater.",
            fact: "Their blue-gray skin looks light blue underwater. Each whale has a distinctive mottled pattern.",
            imageFile: "blue-whale.jpg",
            places: ["North Atlantic", "North Pacific", "Southern Ocean"],
            whereTheyLive: "Blue whales inhabit every ocean except the Arctic. They gather where krill is plentiful, including waters off California, Mexico, eastern Canada, and Antarctica.",
            movement: "Many move between summer feeding areas and winter breeding waters. Routes vary, and some individuals may remain in one region rather than migrate.",
            history: "Industrial whaling in the early 1900s dramatically reduced their numbers. Today’s population remains only a fraction of its size before that period.",
            protection: "Blue whales are endangered under the U.S. Endangered Species Act. Collisions with ships and entanglement in fishing gear remain major threats."
        ),
        WhaleSpecies(
            slug: "humpback-whale", name: "Humpback whale", latin: "Megaptera novaeangliae", type: "Baleen",
            length: "Up to 18 m", diet: "Krill & fish", habitat: "All oceans",
            headline: "Long flippers. Extraordinary journeys.",
            description: "Humpbacks feed in productive waters and many migrate to warmer regions to breed. Their long pectoral flippers and knobbly heads make them easy to recognize.",
            fact: "The markings on the underside of a humpback’s tail help researchers recognize individual whales.",
            imageFile: "humpback-whale.png",
            places: ["Alaska", "Hawaiʻi", "Mexico", "Western Pacific"],
            whereTheyLive: "Humpbacks live across the major oceans. North Pacific populations feed around Alaska and the U.S. West Coast and breed near Hawaiʻi, Mexico, and western Pacific islands.",
            movement: "Many travel between cold feeding waters and warm calving areas. Some groups work together to surround fish with bubbles before lunging upward to feed.",
            history: "Commercial whaling severely reduced humpback populations. International protections helped many groups recover, although that recovery has not been the same everywhere.",
            protection: "U.S. protection varies by population: some remain endangered or threatened. Fishing-gear entanglement and vessel strikes continue to put these whales at risk."
        ),
        WhaleSpecies(
            slug: "sperm-whale", name: "Sperm whale", latin: "Physeter macrocephalus", type: "Toothed",
            length: "Up to 16 m", diet: "Mostly squid", habitat: "Deep oceans",
            headline: "Built for a life in the deep.",
            description: "The sperm whale is the largest toothed whale. Its enormous, squared head and narrow lower jaw set it apart from baleen whales.",
            fact: "Sperm whales use sound to find prey in dark water. Their clicks are part of an echolocation system.",
            imageFile: "sperm-whale.png",
            places: ["Deep ocean waters", "Tropics", "Temperate seas"],
            whereTheyLive: "Sperm whales occupy oceans worldwide, mainly in deep water. Females and young often remain in tropical regions, while adult males can travel into cooler waters.",
            movement: "They dive deeply to hunt squid and other prey, then return to the surface to breathe. Their migration patterns are less predictable than those of many baleen whales.",
            history: "Whalers targeted the oil and spermaceti in their bodies and heads for lamps, candles, and lubricants. Heavy hunting from the 1800s into the 1980s depleted populations.",
            protection: "Sperm whales remain endangered under the U.S. Endangered Species Act. Recovery work includes reducing entanglements, ship collisions, and harmful ocean noise."
        ),
        WhaleSpecies(
            slug: "killer-whale", name: "Orca", latin: "Orcinus orca", type: "Toothed",
            length: "Up to 9.8 m", diet: "Varies by group", habitat: "All oceans",
            headline: "An ocean predator with family traditions.",
            description: "Also called the killer whale, the orca is the largest member of the dolphin family. Different populations specialize in different prey, from fish to marine mammals.",
            fact: "Orcas live in social groups. Feeding habits and vocal patterns can differ between populations.",
            imageFile: "killer-whale.png",
            places: ["North Pacific", "North Atlantic", "Antarctica", "Tropical seas"],
            whereTheyLive: "Orcas inhabit every ocean, with greater numbers in colder regions. They occur in both coastal and offshore waters, including the Pacific Northwest and Antarctic seas.",
            movement: "Family groups use learned calls and hunting techniques. Some populations specialize in fish, while others hunt marine mammals; their diets reflect local traditions.",
            history: "Live captures for marine parks reduced the Southern Resident population during the 1960s. The United States listed that population as endangered in 2005.",
            protection: "Risk differs between populations. Southern Residents face limited salmon supplies, contaminants, and vessel noise; their endangered status does not apply to every orca worldwide."
        ),
        WhaleSpecies(
            slug: "beluga-whale", name: "Beluga", latin: "Delphinapterus leucas", type: "Toothed",
            length: "Up to 4.9 m", diet: "Fish & invertebrates", habitat: "Arctic & subarctic",
            headline: "The white whale of northern waters.",
            description: "Adult belugas are recognizable by their white skin and rounded forehead. Unlike most whales, their necks are flexible enough to turn their heads.",
            fact: "Belugas have no dorsal fin. A low dorsal ridge helps them move beneath sea ice.",
            imageFile: "beluga-whale.png",
            places: ["Alaska", "Canada", "Greenland", "Russia"],
            whereTheyLive: "Belugas live in Arctic and subarctic northern waters. In summer, many gather near shallow coasts, estuaries, and river deltas to feed.",
            movement: "Seasonal movements follow ice conditions and food. Belugas use varied calls and echolocation to communicate, navigate, and locate prey, including in murky water.",
            history: "Alaska’s Cook Inlet population declined sharply between 1979 and 2018. Its changing summer distribution has brought many whales closer to the Anchorage area.",
            protection: "Cook Inlet belugas are endangered under U.S. law; this is a population-specific designation. Noise, habitat disturbance, and reduced food availability can hinder recovery."
        ),
        WhaleSpecies(
            slug: "gray-whale", name: "Gray whale", latin: "Eschrichtius robustus", type: "Baleen",
            length: "Up to 15 m", diet: "Bottom invertebrates", habitat: "North Pacific",
            headline: "A traveler along the ocean’s edge.",
            description: "Gray whales often feed close to the seafloor, filtering small invertebrates from sediment. Their gray skin is patterned with scars, barnacles, and whale lice.",
            fact: "They have a low dorsal hump followed by a series of knuckles, rather than a true dorsal fin.",
            imageFile: "gray-whale.png",
            places: ["North Pacific", "Bering Sea", "Baja California", "Eastern Asia"],
            whereTheyLive: "Gray whales mainly use shallow North Pacific coastal waters. Eastern whales range along North America; western whales are associated with the coast of eastern Asia.",
            movement: "Many eastern whales feed in northern seas during summer and travel south to Baja California’s winter calving areas. They often filter small animals from seafloor sediment.",
            history: "Commercial hunting pushed both Pacific populations close to extinction. Protections supported recovery, and the eastern population was removed from the U.S. endangered list in 1994.",
            protection: "The western population remains endangered under U.S. law. Both populations face risks from fishing gear, vessel strikes, and disturbance along their routes."
        ),
    ]
}
