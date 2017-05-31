package net.minecraft.client.resources.model;

import com.google.common.base.Charsets;
import com.google.common.base.Joiner;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Queues;
import com.google.common.collect.Sets;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.StringReader;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;
import net.minecraft.client.renderer.BlockModelShapes;
import net.minecraft.client.renderer.block.model.BakedQuad;
import net.minecraft.client.renderer.block.model.BlockPart;
import net.minecraft.client.renderer.block.model.BlockPartFace;
import net.minecraft.client.renderer.block.model.FaceBakery;
import net.minecraft.client.renderer.block.model.ItemCameraTransforms;
import net.minecraft.client.renderer.block.model.ItemModelGenerator;
import net.minecraft.client.renderer.block.model.ModelBlock;
import net.minecraft.client.renderer.block.model.ModelBlockDefinition;
import net.minecraft.client.renderer.texture.IIconCreator;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.client.renderer.texture.TextureMap;
import net.minecraft.client.resources.IResource;
import net.minecraft.client.resources.IResourceManager;
import net.minecraft.init.Blocks;
import net.minecraft.init.Items;
import net.minecraft.item.Item;
import net.minecraft.util.EnumFacing;
import net.minecraft.util.IRegistry;
import net.minecraft.util.RegistrySimple;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;
import org.apache.commons.io.IOUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

@SideOnly(Side.CLIENT)
public class ModelBakery
{
    protected static final Set LOCATIONS_BUILTIN_TEXTURES = Sets.newHashSet(new ResourceLocation[] {new ResourceLocation("blocks/water_flow"), new ResourceLocation("blocks/water_still"), new ResourceLocation("blocks/lava_flow"), new ResourceLocation("blocks/lava_still"), new ResourceLocation("blocks/destroy_stage_0"), new ResourceLocation("blocks/destroy_stage_1"), new ResourceLocation("blocks/destroy_stage_2"), new ResourceLocation("blocks/destroy_stage_3"), new ResourceLocation("blocks/destroy_stage_4"), new ResourceLocation("blocks/destroy_stage_5"), new ResourceLocation("blocks/destroy_stage_6"), new ResourceLocation("blocks/destroy_stage_7"), new ResourceLocation("blocks/destroy_stage_8"), new ResourceLocation("blocks/destroy_stage_9"), new ResourceLocation("items/empty_armor_slot_helmet"), new ResourceLocation("items/empty_armor_slot_chestplate"), new ResourceLocation("items/empty_armor_slot_leggings"), new ResourceLocation("items/empty_armor_slot_boots")});
    private static final Logger LOGGER = LogManager.getLogger();
    protected static final ModelResourceLocation MODEL_MISSING = new ModelResourceLocation("builtin/missing", "missing");
    private static final Map BUILT_IN_MODELS = Maps.newHashMap();
    private static final Joiner JOINER;
    protected final IResourceManager resourceManager;
    protected final Map sprites = Maps.newHashMap();
    private final Map models = Maps.newLinkedHashMap();
    private final Map variants = Maps.newLinkedHashMap();
    protected final TextureMap textureMap;
    protected final BlockModelShapes blockModelShapes;
    private final FaceBakery faceBakery = new FaceBakery();
    private final ItemModelGenerator itemModelGenerator = new ItemModelGenerator();
    protected RegistrySimple bakedRegistry = new RegistrySimple();
    protected static final ModelBlock MODEL_GENERATED;
    protected static final ModelBlock MODEL_COMPASS;
    protected static final ModelBlock MODEL_CLOCK;
    protected static final ModelBlock MODEL_ENTITY;
    private Map itemLocations = Maps.newLinkedHashMap();
    private final Map blockDefinitions = Maps.newHashMap();
    private Map variantNames = Maps.newIdentityHashMap();
    private static final String __OBFID = "CL_00002391";

    public ModelBakery(IResourceManager p_i46085_1_, TextureMap p_i46085_2_, BlockModelShapes p_i46085_3_)
    {
        this.resourceManager = p_i46085_1_;
        this.textureMap = p_i46085_2_;
        this.blockModelShapes = p_i46085_3_;
    }

    public IRegistry setupModelRegistry()
    {
        this.loadVariantItemModels();
        this.loadModelsCheck();
        this.loadSprites();
        this.bakeItemModels();
        this.bakeBlockModels();
        return this.bakedRegistry;
    }

    private void loadVariantItemModels()
    {
        this.loadVariants(this.blockModelShapes.getBlockStateMapper().putAllStateModelLocations().values());
        this.variants.put(MODEL_MISSING, new ModelBlockDefinition.Variants(MODEL_MISSING.getVariant(), Lists.newArrayList(new ModelBlockDefinition.Variant[] {new ModelBlockDefinition.Variant(new ResourceLocation(MODEL_MISSING.getResourcePath()), ModelRotation.X0_Y0, false, 1)})));
        ResourceLocation resourcelocation = new ResourceLocation("item_frame");
        ModelBlockDefinition modelblockdefinition = this.getModelBlockDefinition(resourcelocation);
        this.registerVariant(modelblockdefinition, new ModelResourceLocation(resourcelocation, "normal"));
        this.registerVariant(modelblockdefinition, new ModelResourceLocation(resourcelocation, "map"));
        this.loadVariantModels();
        this.loadItemModels();
    }

    protected void loadVariants(Collection p_177591_1_)
    {
        Iterator iterator = p_177591_1_.iterator();

        while (iterator.hasNext())
        {
            ModelResourceLocation modelresourcelocation = (ModelResourceLocation)iterator.next();

            try
            {
                ModelBlockDefinition modelblockdefinition = this.getModelBlockDefinition(modelresourcelocation);

                try
                {
                    this.registerVariant(modelblockdefinition, modelresourcelocation);
                }
                catch (Exception exception)
                {
                    LOGGER.warn("Unable to load variant: " + modelresourcelocation.getVariant() + " from " + modelresourcelocation, exception);
                }
            }
            catch (Exception exception1)
            {
                LOGGER.warn("Unable to load definition " + modelresourcelocation, exception1);
            }
        }
    }

    protected void registerVariant(ModelBlockDefinition p_177569_1_, ModelResourceLocation p_177569_2_)
    {
        this.variants.put(p_177569_2_, p_177569_1_.getVariants(p_177569_2_.getVariant()));
    }

    protected ModelBlockDefinition getModelBlockDefinition(ResourceLocation p_177586_1_)
    {
        ResourceLocation resourcelocation1 = this.getBlockStateLocation(p_177586_1_);
        ModelBlockDefinition modelblockdefinition = (ModelBlockDefinition)this.blockDefinitions.get(resourcelocation1);

        if (modelblockdefinition == null)
        {
            ArrayList arraylist = Lists.newArrayList();

            try
            {
                Iterator iterator = this.resourceManager.getAllResources(resourcelocation1).iterator();

                while (iterator.hasNext())
                {
                    IResource iresource = (IResource)iterator.next();
                    InputStream inputstream = null;

                    try
                    {
                        inputstream = iresource.getInputStream();
                        ModelBlockDefinition modelblockdefinition1 = ModelBlockDefinition.parseFromReader(new InputStreamReader(inputstream, Charsets.UTF_8));
                        arraylist.add(modelblockdefinition1);
                    }
                    catch (Exception exception)
                    {
                        throw new RuntimeException("Encountered an exception when loading model definition of \'" + p_177586_1_ + "\' from: \'" + iresource.getResourceLocation() + "\' in resourcepack: \'" + iresource.getResourcePackName() + "\'", exception);
                    }
                    finally
                    {
                        IOUtils.closeQuietly(inputstream);
                    }
                }
            }
            catch (FileNotFoundException e) {}
            catch (IOException ioexception)
            {
                throw new RuntimeException("Encountered an exception when loading model definition of model " + resourcelocation1.toString(), ioexception);
            }

            modelblockdefinition = new ModelBlockDefinition(arraylist);
            this.blockDefinitions.put(resourcelocation1, modelblockdefinition);
        }

        return modelblockdefinition;
    }

    private ResourceLocation getBlockStateLocation(ResourceLocation p_177584_1_)
    {
        return new ResourceLocation(p_177584_1_.getResourceDomain(), "blockstates/" + p_177584_1_.getResourcePath() + ".json");
    }

    private void loadVariantModels()
    {
        Iterator iterator = this.variants.keySet().iterator();

        while (iterator.hasNext())
        {
            ModelResourceLocation modelresourcelocation = (ModelResourceLocation)iterator.next();
            Iterator iterator1 = ((ModelBlockDefinition.Variants)this.variants.get(modelresourcelocation)).getVariants().iterator();

            while (iterator1.hasNext())
            {
                ModelBlockDefinition.Variant variant = (ModelBlockDefinition.Variant)iterator1.next();
                ResourceLocation resourcelocation = variant.getModelLocation();

                if (this.models.get(resourcelocation) == null)
                {
                    try
                    {
                        ModelBlock modelblock = this.loadModel(resourcelocation);
                        this.models.put(resourcelocation, modelblock);
                    }
                    catch (Exception exception)
                    {
                        LOGGER.warn("Unable to load block model: \'" + resourcelocation + "\' for variant: \'" + modelresourcelocation + "\'", exception);
                    }
                }
            }
        }
    }

    protected ModelBlock loadModel(ResourceLocation p_177594_1_) throws IOException
    {
        String s = p_177594_1_.getResourcePath();

        if ("builtin/generated".equals(s))
        {
            return MODEL_GENERATED;
        }
        else if ("builtin/compass".equals(s))
        {
            return MODEL_COMPASS;
        }
        else if ("builtin/clock".equals(s))
        {
            return MODEL_CLOCK;
        }
        else if ("builtin/entity".equals(s))
        {
            return MODEL_ENTITY;
        }
        else
        {
            Object object;

            if (s.startsWith("builtin/"))
            {
                String s1 = s.substring("builtin/".length());
                String s2 = (String)BUILT_IN_MODELS.get(s1);

                if (s2 == null)
                {
                    throw new FileNotFoundException(p_177594_1_.toString());
                }

                object = new StringReader(s2);
            }
            else
            {
                IResource iresource = this.resourceManager.getResource(this.getModelLocation(p_177594_1_));
                object = new InputStreamReader(iresource.getInputStream(), Charsets.UTF_8);
            }

            ModelBlock modelblock1;

            try
            {
                ModelBlock modelblock = ModelBlock.deserialize((Reader)object);
                modelblock.name = p_177594_1_.toString();
                modelblock1 = modelblock;
            }
            finally
            {
                ((Reader)object).close();
            }

            return modelblock1;
        }
    }

    protected ResourceLocation getModelLocation(ResourceLocation p_177580_1_)
    {
        return new ResourceLocation(p_177580_1_.getResourceDomain(), "models/" + p_177580_1_.getResourcePath() + ".json");
    }

    private void loadItemModels()
    {
        this.registerVariantNames();
        Iterator iterator = Item.itemRegistry.iterator();

        while (iterator.hasNext())
        {
            Item item = (Item)iterator.next();
            List list = this.getVariantNames(item);
            Iterator iterator1 = list.iterator();

            while (iterator1.hasNext())
            {
                String s = (String)iterator1.next();
                ResourceLocation resourcelocation = this.getItemLocation(s);
                this.itemLocations.put(s, resourcelocation);

                if (this.models.get(resourcelocation) == null)
                {
                    try
                    {
                        ModelBlock modelblock = this.loadModel(resourcelocation);
                        this.models.put(resourcelocation, modelblock);
                    }
                    catch (Exception exception)
                    {
                        LOGGER.warn("Unable to load item model: \'" + resourcelocation + "\' for item: \'" + Item.itemRegistry.getNameForObject(item) + "\'", exception);
                    }
                }
            }
        }
    }

    protected void registerVariantNames()
    {
        this.variantNames.clear(); //FML clear this to prevent double ups.
        this.variantNames.put(Item.getItemFromBlock(Blocks.stone), Lists.newArrayList(new String[] {"stone", "granite", "granite_smooth", "diorite", "diorite_smooth", "andesite", "andesite_smooth"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.dirt), Lists.newArrayList(new String[] {"dirt", "coarse_dirt", "podzol"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.planks), Lists.newArrayList(new String[] {"oak_planks", "spruce_planks", "birch_planks", "jungle_planks", "acacia_planks", "dark_oak_planks"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.sapling), Lists.newArrayList(new String[] {"oak_sapling", "spruce_sapling", "birch_sapling", "jungle_sapling", "acacia_sapling", "dark_oak_sapling"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.sand), Lists.newArrayList(new String[] {"sand", "red_sand"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.log), Lists.newArrayList(new String[] {"oak_log", "spruce_log", "birch_log", "jungle_log"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.leaves), Lists.newArrayList(new String[] {"oak_leaves", "spruce_leaves", "birch_leaves", "jungle_leaves"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.sponge), Lists.newArrayList(new String[] {"sponge", "sponge_wet"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.sandstone), Lists.newArrayList(new String[] {"sandstone", "chiseled_sandstone", "smooth_sandstone"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.red_sandstone), Lists.newArrayList(new String[] {"red_sandstone", "chiseled_red_sandstone", "smooth_red_sandstone"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.tallgrass), Lists.newArrayList(new String[] {"dead_bush", "tall_grass", "fern"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.deadbush), Lists.newArrayList(new String[] {"dead_bush"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.wool), Lists.newArrayList(new String[] {"black_wool", "red_wool", "green_wool", "brown_wool", "blue_wool", "purple_wool", "cyan_wool", "silver_wool", "gray_wool", "pink_wool", "lime_wool", "yellow_wool", "light_blue_wool", "magenta_wool", "orange_wool", "white_wool"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.yellow_flower), Lists.newArrayList(new String[] {"dandelion"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.red_flower), Lists.newArrayList(new String[] {"poppy", "blue_orchid", "allium", "houstonia", "red_tulip", "orange_tulip", "white_tulip", "pink_tulip", "oxeye_daisy"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.stone_slab), Lists.newArrayList(new String[] {"stone_slab", "sandstone_slab", "cobblestone_slab", "brick_slab", "stone_brick_slab", "nether_brick_slab", "quartz_slab"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.stone_slab2), Lists.newArrayList(new String[] {"red_sandstone_slab"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.stained_glass), Lists.newArrayList(new String[] {"black_stained_glass", "red_stained_glass", "green_stained_glass", "brown_stained_glass", "blue_stained_glass", "purple_stained_glass", "cyan_stained_glass", "silver_stained_glass", "gray_stained_glass", "pink_stained_glass", "lime_stained_glass", "yellow_stained_glass", "light_blue_stained_glass", "magenta_stained_glass", "orange_stained_glass", "white_stained_glass"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.monster_egg), Lists.newArrayList(new String[] {"stone_monster_egg", "cobblestone_monster_egg", "stone_brick_monster_egg", "mossy_brick_monster_egg", "cracked_brick_monster_egg", "chiseled_brick_monster_egg"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.stonebrick), Lists.newArrayList(new String[] {"stonebrick", "mossy_stonebrick", "cracked_stonebrick", "chiseled_stonebrick"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.wooden_slab), Lists.newArrayList(new String[] {"oak_slab", "spruce_slab", "birch_slab", "jungle_slab", "acacia_slab", "dark_oak_slab"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.cobblestone_wall), Lists.newArrayList(new String[] {"cobblestone_wall", "mossy_cobblestone_wall"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.anvil), Lists.newArrayList(new String[] {"anvil_intact", "anvil_slightly_damaged", "anvil_very_damaged"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.quartz_block), Lists.newArrayList(new String[] {"quartz_block", "chiseled_quartz_block", "quartz_column"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.stained_hardened_clay), Lists.newArrayList(new String[] {"black_stained_hardened_clay", "red_stained_hardened_clay", "green_stained_hardened_clay", "brown_stained_hardened_clay", "blue_stained_hardened_clay", "purple_stained_hardened_clay", "cyan_stained_hardened_clay", "silver_stained_hardened_clay", "gray_stained_hardened_clay", "pink_stained_hardened_clay", "lime_stained_hardened_clay", "yellow_stained_hardened_clay", "light_blue_stained_hardened_clay", "magenta_stained_hardened_clay", "orange_stained_hardened_clay", "white_stained_hardened_clay"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.stained_glass_pane), Lists.newArrayList(new String[] {"black_stained_glass_pane", "red_stained_glass_pane", "green_stained_glass_pane", "brown_stained_glass_pane", "blue_stained_glass_pane", "purple_stained_glass_pane", "cyan_stained_glass_pane", "silver_stained_glass_pane", "gray_stained_glass_pane", "pink_stained_glass_pane", "lime_stained_glass_pane", "yellow_stained_glass_pane", "light_blue_stained_glass_pane", "magenta_stained_glass_pane", "orange_stained_glass_pane", "white_stained_glass_pane"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.leaves2), Lists.newArrayList(new String[] {"acacia_leaves", "dark_oak_leaves"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.log2), Lists.newArrayList(new String[] {"acacia_log", "dark_oak_log"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.prismarine), Lists.newArrayList(new String[] {"prismarine", "prismarine_bricks", "dark_prismarine"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.carpet), Lists.newArrayList(new String[] {"black_carpet", "red_carpet", "green_carpet", "brown_carpet", "blue_carpet", "purple_carpet", "cyan_carpet", "silver_carpet", "gray_carpet", "pink_carpet", "lime_carpet", "yellow_carpet", "light_blue_carpet", "magenta_carpet", "orange_carpet", "white_carpet"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.double_plant), Lists.newArrayList(new String[] {"sunflower", "syringa", "double_grass", "double_fern", "double_rose", "paeonia"}));
        this.variantNames.put(Items.bow, Lists.newArrayList(new String[] {"bow", "bow_pulling_0", "bow_pulling_1", "bow_pulling_2"}));
        this.variantNames.put(Items.coal, Lists.newArrayList(new String[] {"coal", "charcoal"}));
        this.variantNames.put(Items.fishing_rod, Lists.newArrayList(new String[] {"fishing_rod", "fishing_rod_cast"}));
        this.variantNames.put(Items.fish, Lists.newArrayList(new String[] {"cod", "salmon", "clownfish", "pufferfish"}));
        this.variantNames.put(Items.cooked_fish, Lists.newArrayList(new String[] {"cooked_cod", "cooked_salmon"}));
        this.variantNames.put(Items.dye, Lists.newArrayList(new String[] {"dye_black", "dye_red", "dye_green", "dye_brown", "dye_blue", "dye_purple", "dye_cyan", "dye_silver", "dye_gray", "dye_pink", "dye_lime", "dye_yellow", "dye_light_blue", "dye_magenta", "dye_orange", "dye_white"}));
        this.variantNames.put(Items.potionitem, Lists.newArrayList(new String[] {"bottle_drinkable", "bottle_splash"}));
        this.variantNames.put(Items.skull, Lists.newArrayList(new String[] {"skull_skeleton", "skull_wither", "skull_zombie", "skull_char", "skull_creeper"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.oak_fence_gate), Lists.newArrayList(new String[] {"oak_fence_gate"}));
        this.variantNames.put(Item.getItemFromBlock(Blocks.oak_fence), Lists.newArrayList(new String[] {"oak_fence"}));
        this.variantNames.put(Items.oak_door, Lists.newArrayList(new String[] {"oak_door"}));
        for (Entry<net.minecraftforge.fml.common.registry.RegistryDelegate<Item>, Set<String>> e : customVariantNames.entrySet())
        {
            this.variantNames.put(e.getKey().get(), Lists.newArrayList(e.getValue().iterator()));
        }
    }

    protected List getVariantNames(Item p_177596_1_)
    {
        List list = (List)this.variantNames.get(p_177596_1_);

        if (list == null)
        {
            list = Collections.singletonList(((ResourceLocation)Item.itemRegistry.getNameForObject(p_177596_1_)).toString());
        }

        return list;
    }

    protected ResourceLocation getItemLocation(String p_177583_1_)
    {
        ResourceLocation resourcelocation = new ResourceLocation(p_177583_1_);
        return new ResourceLocation(resourcelocation.getResourceDomain(), "item/" + resourcelocation.getResourcePath());
    }

    private void bakeBlockModels()
    {
        Iterator iterator = this.variants.keySet().iterator();

        while (iterator.hasNext())
        {
            ModelResourceLocation modelresourcelocation = (ModelResourceLocation)iterator.next();
            WeightedBakedModel.Builder builder = new WeightedBakedModel.Builder();
            int i = 0;
            Iterator iterator1 = ((ModelBlockDefinition.Variants)this.variants.get(modelresourcelocation)).getVariants().iterator();

            while (iterator1.hasNext())
            {
                ModelBlockDefinition.Variant variant = (ModelBlockDefinition.Variant)iterator1.next();
                ModelBlock modelblock = (ModelBlock)this.models.get(variant.getModelLocation());

                if (modelblock != null && modelblock.isResolved())
                {
                    ++i;
                    builder.add(this.bakeModel(modelblock, variant.getRotation(), variant.isUvLocked()), variant.getWeight());
                }
                else
                {
                    LOGGER.warn("Missing model for: " + modelresourcelocation);
                }
            }

            if (i == 0)
            {
                LOGGER.warn("No weighted models for: " + modelresourcelocation);
            }
            else if (i == 1)
            {
                this.bakedRegistry.putObject(modelresourcelocation, builder.first());
            }
            else
            {
                this.bakedRegistry.putObject(modelresourcelocation, builder.build());
            }
        }

        iterator = this.itemLocations.entrySet().iterator();

        while (iterator.hasNext())
        {
            Entry entry = (Entry)iterator.next();
            ResourceLocation resourcelocation = (ResourceLocation)entry.getValue();
            ModelResourceLocation modelresourcelocation1 = new ModelResourceLocation((String)entry.getKey(), "inventory");
            ModelBlock modelblock1 = (ModelBlock)this.models.get(resourcelocation);

            if (modelblock1 != null && modelblock1.isResolved())
            {
                if (this.isCustomRenderer(modelblock1))
                {
                    this.bakedRegistry.putObject(modelresourcelocation1, new BuiltInModel(new ItemCameraTransforms(modelblock1.getThirdPersonTransform(), modelblock1.getFirstPersonTransform(), modelblock1.getHeadTransform(), modelblock1.getInGuiTransform())));
                }
                else
                {
                    this.bakedRegistry.putObject(modelresourcelocation1, this.bakeModel(modelblock1, ModelRotation.X0_Y0, false));
                }
            }
            else
            {
                LOGGER.warn("Missing model for: " + resourcelocation);
            }
        }
    }

    private Set getVariantsTextureLocations()
    {
        HashSet hashset = Sets.newHashSet();
        ArrayList arraylist = Lists.newArrayList(this.variants.keySet());
        Collections.sort(arraylist, new Comparator()
        {
            private static final String __OBFID = "CL_00002390";
            public int func_177505_a(ModelResourceLocation p_177505_1_, ModelResourceLocation p_177505_2_)
            {
                return p_177505_1_.toString().compareTo(p_177505_2_.toString());
            }
            public int compare(Object p_compare_1_, Object p_compare_2_)
            {
                return this.func_177505_a((ModelResourceLocation)p_compare_1_, (ModelResourceLocation)p_compare_2_);
            }
        });
        Iterator iterator = arraylist.iterator();

        while (iterator.hasNext())
        {
            ModelResourceLocation modelresourcelocation = (ModelResourceLocation)iterator.next();
            ModelBlockDefinition.Variants variants = (ModelBlockDefinition.Variants)this.variants.get(modelresourcelocation);
            Iterator iterator1 = variants.getVariants().iterator();

            while (iterator1.hasNext())
            {
                ModelBlockDefinition.Variant variant = (ModelBlockDefinition.Variant)iterator1.next();
                ModelBlock modelblock = (ModelBlock)this.models.get(variant.getModelLocation());

                if (modelblock == null)
                {
                    LOGGER.warn("Missing model for: " + modelresourcelocation);
                }
                else
                {
                    hashset.addAll(this.getTextureLocations(modelblock));
                }
            }
        }

        hashset.addAll(LOCATIONS_BUILTIN_TEXTURES);
        return hashset;
    }

    private IBakedModel bakeModel(ModelBlock modelBlockIn, ModelRotation modelRotationIn, boolean uvLocked)
    {
        return bakeModel(modelBlockIn, (net.minecraftforge.client.model.ITransformation)modelRotationIn, uvLocked);
    }

    protected IBakedModel bakeModel(ModelBlock modelBlockIn, net.minecraftforge.client.model.ITransformation modelRotationIn, boolean uvLocked)
    {
        TextureAtlasSprite textureatlassprite = (TextureAtlasSprite)this.sprites.get(new ResourceLocation(modelBlockIn.resolveTextureName("particle")));
        SimpleBakedModel.Builder builder = (new SimpleBakedModel.Builder(modelBlockIn)).setTexture(textureatlassprite);
        Iterator iterator = modelBlockIn.getElements().iterator();

        while (iterator.hasNext())
        {
            BlockPart blockpart = (BlockPart)iterator.next();
            Iterator iterator1 = blockpart.mapFaces.keySet().iterator();

            while (iterator1.hasNext())
            {
                EnumFacing enumfacing = (EnumFacing)iterator1.next();
                BlockPartFace blockpartface = (BlockPartFace)blockpart.mapFaces.get(enumfacing);
                TextureAtlasSprite textureatlassprite1 = (TextureAtlasSprite)this.sprites.get(new ResourceLocation(modelBlockIn.resolveTextureName(blockpartface.texture)));

                if (blockpartface.cullFace == null || !net.minecraftforge.client.model.TRSRTransformation.isInteger(modelRotationIn.getMatrix()))
                {
                    builder.addGeneralQuad(this.makeBakedQuad(blockpart, blockpartface, textureatlassprite1, enumfacing, modelRotationIn, uvLocked));
                }
                else
                {
                    builder.addFaceQuad(modelRotationIn.rotate(blockpartface.cullFace), this.makeBakedQuad(blockpart, blockpartface, textureatlassprite1, enumfacing, modelRotationIn, uvLocked));
                }
            }
        }

        return builder.makeBakedModel();
    }

    private BakedQuad makeBakedQuad(BlockPart p_177589_1_, BlockPartFace p_177589_2_, TextureAtlasSprite p_177589_3_, EnumFacing p_177589_4_, ModelRotation p_177589_5_, boolean p_177589_6_)
    {
        return makeBakedQuad(p_177589_1_, p_177589_2_, p_177589_3_, p_177589_4_, (net.minecraftforge.client.model.ITransformation)p_177589_5_, p_177589_6_);
    }

    protected BakedQuad makeBakedQuad(BlockPart p_177589_1_, BlockPartFace p_177589_2_, TextureAtlasSprite p_177589_3_, EnumFacing p_177589_4_, net.minecraftforge.client.model.ITransformation p_177589_5_, boolean p_177589_6_)
    {
        return this.faceBakery.makeBakedQuad(p_177589_1_.positionFrom, p_177589_1_.positionTo, p_177589_2_, p_177589_3_, p_177589_4_, p_177589_5_, p_177589_1_.partRotation, p_177589_6_, p_177589_1_.shade);
    }

    private void loadModelsCheck()
    {
        this.loadModels();
        Iterator iterator = this.models.values().iterator();

        while (iterator.hasNext())
        {
            ModelBlock modelblock = (ModelBlock)iterator.next();
            modelblock.getParentFromMap(this.models);
        }

        ModelBlock.checkModelHierarchy(this.models);
    }

    private void loadModels()
    {
        ArrayDeque arraydeque = Queues.newArrayDeque();
        HashSet hashset = Sets.newHashSet();
        Iterator iterator = this.models.keySet().iterator();
        ResourceLocation resourcelocation1;

        while (iterator.hasNext())
        {
            ResourceLocation resourcelocation = (ResourceLocation)iterator.next();
            hashset.add(resourcelocation);
            resourcelocation1 = ((ModelBlock)this.models.get(resourcelocation)).getParentLocation();

            if (resourcelocation1 != null)
            {
                arraydeque.add(resourcelocation1);
            }
        }

        while (!arraydeque.isEmpty())
        {
            ResourceLocation resourcelocation2 = (ResourceLocation)arraydeque.pop();

            try
            {
                if (this.models.get(resourcelocation2) != null)
                {
                    continue;
                }

                ModelBlock modelblock = this.loadModel(resourcelocation2);
                this.models.put(resourcelocation2, modelblock);
                resourcelocation1 = modelblock.getParentLocation();

                if (resourcelocation1 != null && !hashset.contains(resourcelocation1))
                {
                    arraydeque.add(resourcelocation1);
                }
            }
            catch (Exception exception)
            {
                LOGGER.warn("In parent chain: " + JOINER.join(this.getParentPath(resourcelocation2)) + "; unable to load model: \'" + resourcelocation2 + "\'", exception);
            }

            hashset.add(resourcelocation2);
        }
    }

    private List getParentPath(ResourceLocation p_177573_1_)
    {
        ArrayList arraylist = Lists.newArrayList(new ResourceLocation[] {p_177573_1_});
        ResourceLocation resourcelocation1 = p_177573_1_;

        while ((resourcelocation1 = this.getParentLocation(resourcelocation1)) != null)
        {
            arraylist.add(0, resourcelocation1);
        }

        return arraylist;
    }

    private ResourceLocation getParentLocation(ResourceLocation p_177576_1_)
    {
        Iterator iterator = this.models.entrySet().iterator();
        Entry entry;
        ModelBlock modelblock;

        do
        {
            if (!iterator.hasNext())
            {
                return null;
            }

            entry = (Entry)iterator.next();
            modelblock = (ModelBlock)entry.getValue();
        }
        while (modelblock == null || !p_177576_1_.equals(modelblock.getParentLocation()));

        return (ResourceLocation)entry.getKey();
    }

    protected Set getTextureLocations(ModelBlock p_177585_1_)
    {
        HashSet hashset = Sets.newHashSet();
        Iterator iterator = p_177585_1_.getElements().iterator();

        while (iterator.hasNext())
        {
            BlockPart blockpart = (BlockPart)iterator.next();
            Iterator iterator1 = blockpart.mapFaces.values().iterator();

            while (iterator1.hasNext())
            {
                BlockPartFace blockpartface = (BlockPartFace)iterator1.next();
                ResourceLocation resourcelocation = new ResourceLocation(p_177585_1_.resolveTextureName(blockpartface.texture));
                hashset.add(resourcelocation);
            }
        }

        hashset.add(new ResourceLocation(p_177585_1_.resolveTextureName("particle")));
        return hashset;
    }

    private void loadSprites()
    {
        final Set set = this.getVariantsTextureLocations();
        set.addAll(this.getItemsTextureLocations());
        set.remove(TextureMap.LOCATION_MISSING_TEXTURE);
        IIconCreator iiconcreator = new IIconCreator()
        {
            private static final String __OBFID = "CL_00002389";
            public void registerSprites(TextureMap iconRegistry)
            {
                Iterator iterator = set.iterator();

                while (iterator.hasNext())
                {
                    ResourceLocation resourcelocation = (ResourceLocation)iterator.next();
                    TextureAtlasSprite textureatlassprite = iconRegistry.registerSprite(resourcelocation);
                    ModelBakery.this.sprites.put(resourcelocation, textureatlassprite);
                }
            }
        };
        this.textureMap.loadSprites(this.resourceManager, iiconcreator);
        this.sprites.put(new ResourceLocation("missingno"), this.textureMap.getMissingSprite());
    }

    private Set getItemsTextureLocations()
    {
        HashSet hashset = Sets.newHashSet();
        Iterator iterator = this.itemLocations.values().iterator();

        while (iterator.hasNext())
        {
            ResourceLocation resourcelocation = (ResourceLocation)iterator.next();
            ModelBlock modelblock = (ModelBlock)this.models.get(resourcelocation);

            if (modelblock != null)
            {
                hashset.add(new ResourceLocation(modelblock.resolveTextureName("particle")));
                Iterator iterator1;
                ResourceLocation resourcelocation2;

                if (this.hasItemModel(modelblock))
                {
                    for (iterator1 = ItemModelGenerator.LAYERS.iterator(); iterator1.hasNext(); hashset.add(resourcelocation2))
                    {
                        String s = (String)iterator1.next();
                        resourcelocation2 = new ResourceLocation(modelblock.resolveTextureName(s));

                        if (modelblock.getRootModel() == MODEL_COMPASS && !TextureMap.LOCATION_MISSING_TEXTURE.equals(resourcelocation2))
                        {
                            TextureAtlasSprite.setLocationNameCompass(resourcelocation2.toString());
                        }
                        else if (modelblock.getRootModel() == MODEL_CLOCK && !TextureMap.LOCATION_MISSING_TEXTURE.equals(resourcelocation2))
                        {
                            TextureAtlasSprite.setLocationNameClock(resourcelocation2.toString());
                        }
                    }
                }
                else if (!this.isCustomRenderer(modelblock))
                {
                    iterator1 = modelblock.getElements().iterator();

                    while (iterator1.hasNext())
                    {
                        BlockPart blockpart = (BlockPart)iterator1.next();
                        Iterator iterator2 = blockpart.mapFaces.values().iterator();

                        while (iterator2.hasNext())
                        {
                            BlockPartFace blockpartface = (BlockPartFace)iterator2.next();
                            ResourceLocation resourcelocation1 = new ResourceLocation(modelblock.resolveTextureName(blockpartface.texture));
                            hashset.add(resourcelocation1);
                        }
                    }
                }
            }
        }

        return hashset;
    }

    protected boolean hasItemModel(ModelBlock p_177581_1_)
    {
        if (p_177581_1_ == null)
        {
            return false;
        }
        else
        {
            ModelBlock modelblock1 = p_177581_1_.getRootModel();
            return modelblock1 == MODEL_GENERATED || modelblock1 == MODEL_COMPASS || modelblock1 == MODEL_CLOCK;
        }
    }

    protected boolean isCustomRenderer(ModelBlock p_177587_1_)
    {
        if (p_177587_1_ == null)
        {
            return false;
        }
        else
        {
            ModelBlock modelblock1 = p_177587_1_.getRootModel();
            return modelblock1 == MODEL_ENTITY;
        }
    }

    private void bakeItemModels()
    {
        Iterator iterator = this.itemLocations.values().iterator();

        while (iterator.hasNext())
        {
            ResourceLocation resourcelocation = (ResourceLocation)iterator.next();
            ModelBlock modelblock = (ModelBlock)this.models.get(resourcelocation);

            if (this.hasItemModel(modelblock))
            {
                ModelBlock modelblock1 = this.makeItemModel(modelblock);

                if (modelblock1 != null)
                {
                    modelblock1.name = resourcelocation.toString();
                }

                this.models.put(resourcelocation, modelblock1);
            }
            else if (this.isCustomRenderer(modelblock))
            {
                this.models.put(resourcelocation, modelblock);
            }
        }

        iterator = this.sprites.values().iterator();

        while (iterator.hasNext())
        {
            TextureAtlasSprite textureatlassprite = (TextureAtlasSprite)iterator.next();

            if (!textureatlassprite.hasAnimationMetadata())
            {
                textureatlassprite.clearFramesTextureData();
            }
        }
    }

    protected ModelBlock makeItemModel(ModelBlock p_177582_1_)
    {
        return this.itemModelGenerator.makeItemModel(this.textureMap, p_177582_1_);
    }

    static
    {
        BUILT_IN_MODELS.put("missing", "{ \"textures\": {   \"particle\": \"missingno\",   \"missingno\": \"missingno\"}, \"elements\": [ {     \"from\": [ 0, 0, 0 ],     \"to\": [ 16, 16, 16 ],     \"faces\": {         \"down\":  { \"uv\": [ 0, 0, 16, 16 ], \"cullface\": \"down\", \"texture\": \"#missingno\" },         \"up\":    { \"uv\": [ 0, 0, 16, 16 ], \"cullface\": \"up\", \"texture\": \"#missingno\" },         \"north\": { \"uv\": [ 0, 0, 16, 16 ], \"cullface\": \"north\", \"texture\": \"#missingno\" },         \"south\": { \"uv\": [ 0, 0, 16, 16 ], \"cullface\": \"south\", \"texture\": \"#missingno\" },         \"west\":  { \"uv\": [ 0, 0, 16, 16 ], \"cullface\": \"west\", \"texture\": \"#missingno\" },         \"east\":  { \"uv\": [ 0, 0, 16, 16 ], \"cullface\": \"east\", \"texture\": \"#missingno\" }    }}]}");
        JOINER = Joiner.on(" -> ");
        MODEL_GENERATED = ModelBlock.deserialize("{\"elements\":[{  \"from\": [0, 0, 0],   \"to\": [16, 16, 16],   \"faces\": {       \"down\": {\"uv\": [0, 0, 16, 16], \"texture\":\"\"}   }}]}");
        MODEL_COMPASS = ModelBlock.deserialize("{\"elements\":[{  \"from\": [0, 0, 0],   \"to\": [16, 16, 16],   \"faces\": {       \"down\": {\"uv\": [0, 0, 16, 16], \"texture\":\"\"}   }}]}");
        MODEL_CLOCK = ModelBlock.deserialize("{\"elements\":[{  \"from\": [0, 0, 0],   \"to\": [16, 16, 16],   \"faces\": {       \"down\": {\"uv\": [0, 0, 16, 16], \"texture\":\"\"}   }}]}");
        MODEL_ENTITY = ModelBlock.deserialize("{\"elements\":[{  \"from\": [0, 0, 0],   \"to\": [16, 16, 16],   \"faces\": {       \"down\": {\"uv\": [0, 0, 16, 16], \"texture\":\"\"}   }}]}");
        MODEL_GENERATED.name = "generation marker";
        MODEL_COMPASS.name = "compass generation marker";
        MODEL_CLOCK.name = "class generation marker";
        MODEL_ENTITY.name = "block entity marker";
    }
    
    /***********************************************************
     * FML Start
     ***********************************************************/
    private static Map<net.minecraftforge.fml.common.registry.RegistryDelegate<Item>, Set<String>> customVariantNames = Maps.newHashMap();
    public static void addVariantName(Item item, String... names)
    {
        if (customVariantNames.containsKey(item.delegate))
            customVariantNames.get(item.delegate).addAll(Lists.newArrayList(names));
        else
            customVariantNames.put(item.delegate, Sets.newHashSet(names));
    }
    /***********************************************************
     * FML End
     ***********************************************************/
}