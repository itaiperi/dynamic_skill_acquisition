package net.minecraft.block;

import net.minecraft.block.material.Material;
import net.minecraft.block.state.IBlockState;
import net.minecraft.creativetab.CreativeTabs;
import net.minecraft.entity.EntityLivingBase;
import net.minecraft.entity.player.EntityPlayer;
import net.minecraft.init.Blocks;
import net.minecraft.item.ItemStack;
import net.minecraft.tileentity.TileEntity;
import net.minecraft.tileentity.TileEntityBeacon;
import net.minecraft.util.BlockPos;
import net.minecraft.util.EnumFacing;
import net.minecraft.util.EnumWorldBlockLayer;
import net.minecraft.util.HttpUtil;
import net.minecraft.world.World;
import net.minecraft.world.WorldServer;
import net.minecraft.world.chunk.Chunk;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;

public class BlockBeacon extends BlockContainer
{
    private static final String __OBFID = "CL_00000197";

    public BlockBeacon()
    {
        super(Material.glass);
        this.setHardness(3.0F);
        this.setCreativeTab(CreativeTabs.tabMisc);
    }

    /**
     * Returns a new instance of a block's tile entity class. Called on placing the block.
     */
    public TileEntity createNewTileEntity(World worldIn, int meta)
    {
        return new TileEntityBeacon();
    }

    public boolean onBlockActivated(World worldIn, BlockPos pos, IBlockState state, EntityPlayer playerIn, EnumFacing side, float hitX, float hitY, float hitZ)
    {
        if (worldIn.isRemote)
        {
            return true;
        }
        else
        {
            TileEntity tileentity = worldIn.getTileEntity(pos);

            if (tileentity instanceof TileEntityBeacon)
            {
                playerIn.displayGUIChest((TileEntityBeacon)tileentity);
            }

            return true;
        }
    }

    public boolean isOpaqueCube()
    {
        return false;
    }

    public boolean isFullCube()
    {
        return false;
    }

    /**
     * The type of render function that is called for this block
     */
    public int getRenderType()
    {
        return 3;
    }

    public void onBlockPlacedBy(World worldIn, BlockPos pos, IBlockState state, EntityLivingBase placer, ItemStack stack)
    {
        super.onBlockPlacedBy(worldIn, pos, state, placer, stack);

        if (stack.hasDisplayName())
        {
            TileEntity tileentity = worldIn.getTileEntity(pos);

            if (tileentity instanceof TileEntityBeacon)
            {
                ((TileEntityBeacon)tileentity).func_145999_a(stack.getDisplayName());
            }
        }
    }

    /**
     * Called when a neighboring block changes.
     */
    public void onNeighborBlockChange(World worldIn, BlockPos pos, IBlockState state, Block neighborBlock)
    {
        TileEntity tileentity = worldIn.getTileEntity(pos);

        if (tileentity instanceof TileEntityBeacon)
        {
            ((TileEntityBeacon)tileentity).func_174908_m();
            worldIn.addBlockEvent(pos, this, 1, 0);
        }
    }

    @SideOnly(Side.CLIENT)
    public EnumWorldBlockLayer getBlockLayer()
    {
        return EnumWorldBlockLayer.CUTOUT;
    }

    public static void updateColorAsync(final World worldIn, final BlockPos glassPos)
    {
        HttpUtil.field_180193_a.submit(new Runnable()
        {
            private static final String __OBFID = "CL_00002136";
            public void run()
            {
                Chunk chunk = worldIn.getChunkFromBlockCoords(glassPos);

                for (int i = glassPos.getY() - 1; i >= 0; --i)
                {
                    final BlockPos blockpos = new BlockPos(glassPos.getX(), i, glassPos.getZ());

                    if (!chunk.canSeeSky(blockpos))
                    {
                        break;
                    }

                    IBlockState iblockstate = worldIn.getBlockState(blockpos);

                    if (iblockstate.getBlock() == Blocks.beacon)
                    {
                        ((WorldServer)worldIn).addScheduledTask(new Runnable()
                        {
                            private static final String __OBFID = "CL_00002135";
                            public void run()
                            {
                                TileEntity tileentity = worldIn.getTileEntity(blockpos);

                                if (tileentity instanceof TileEntityBeacon)
                                {
                                    ((TileEntityBeacon)tileentity).func_174908_m();
                                    worldIn.addBlockEvent(blockpos, Blocks.beacon, 1, 0);
                                }
                            }
                        });
                    }
                }
            }
        });
    }
}