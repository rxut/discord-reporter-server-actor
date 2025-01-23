class DiscordReporterMutator extends Mutator;

var DiscordReporterStats Stats;
var DiscordReporterConfig conf;

function bool HandlePickupQuery(Pawn Other, Inventory item, out byte bAllowPickup)
{
    local PlayerReplicationInfo PRI;

    if (Stats == None || Other == None || Item == None)
        return Super.HandlePickupQuery(Other, Item, bAllowPickup);

    PRI = Other.PlayerReplicationInfo;
    
    if (PRI != None)
    {
        if (Item.IsA('UDamage'))
            Stats.SendMessage(Stats.bold(PRI.PlayerName) @ "picked up Damage Amplifier!");
        else if (Item.IsA('UT_ShieldBelt'))
            Stats.SendMessage(Stats.bold(PRI.PlayerName) @ "picked up Shield Belt!");
        else if (Item.IsA('Armor2'))
            Stats.SendMessage(Stats.bold(PRI.PlayerName) @ "picked up Body Armor!");
        else if (Item.IsA('ThighPads'))
            Stats.SendMessage(Stats.bold(PRI.PlayerName) @ "picked up Thigh Pads!");
        else if (Item.IsA('UT_Invisibility'))
            Stats.SendMessage(Stats.bold(PRI.PlayerName) @ "picked up Invisibility!");
        else if (Item.IsA('UT_JumpBoots'))
            Stats.SendMessage(Stats.bold(PRI.PlayerName) @ "picked up Jump Boots!");
    }

    if (NextMutator != None)
        return NextMutator.HandlePickupQuery(Other, item, bAllowPickup);
}