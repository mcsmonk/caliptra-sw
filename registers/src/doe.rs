// Licensed under the Apache-2.0 license.
//
// generated by caliptra_registers_generator with caliptra-rtl repo at d334c84a0e513a3d66a51078f020a414a2c86a67
//
#![allow(clippy::erasing_op)]
#![allow(clippy::identity_op)]
/// A zero-sized type that represents ownership of this
/// peripheral, used to get access to a Register lock. Most
/// programs create one of these in unsafe code near the top of
/// main(), and pass it to the driver responsible for managing
/// all access to the hardware.
pub struct DoeReg {
    _priv: (),
}
impl DoeReg {
    pub const PTR: *mut u32 = 0x10000000 as *mut u32;
    /// # Safety
    ///
    /// Caller must ensure that all concurrent use of this
    /// peripheral in the firmware is done so in a compatible
    /// way. The simplest way to enforce this is to only call
    /// this function once.
    pub unsafe fn new() -> Self {
        Self { _priv: () }
    }
    /// Returns a register block that can be used to read
    /// registers from this peripheral, but cannot write.
    pub fn regs(&self) -> RegisterBlock<ureg::RealMmio> {
        RegisterBlock {
            ptr: Self::PTR,
            mmio: core::default::Default::default(),
        }
    }
    /// Return a register block that can be used to read and
    /// write this peripheral's registers.
    pub fn regs_mut(&mut self) -> RegisterBlock<ureg::RealMmioMut> {
        RegisterBlock {
            ptr: Self::PTR,
            mmio: core::default::Default::default(),
        }
    }
}
#[derive(Clone, Copy)]
pub struct RegisterBlock<TMmio: ureg::Mmio + core::borrow::Borrow<TMmio>> {
    ptr: *mut u32,
    mmio: TMmio,
}
impl<TMmio: ureg::Mmio + core::default::Default> RegisterBlock<TMmio> {
    /// # Safety
    ///
    /// The caller is responsible for ensuring that ptr is valid for
    /// volatile reads and writes at any of the offsets in this register
    /// block.
    pub unsafe fn new(ptr: *mut u32) -> Self {
        Self {
            ptr,
            mmio: core::default::Default::default(),
        }
    }
}
impl<TMmio: ureg::Mmio> RegisterBlock<TMmio> {
    /// # Safety
    ///
    /// The caller is responsible for ensuring that ptr is valid for
    /// volatile reads and writes at any of the offsets in this register
    /// block.
    pub unsafe fn new_with_mmio(ptr: *mut u32, mmio: TMmio) -> Self {
        Self { ptr, mmio }
    }
    /// 4 32-bit registers storing the 128-bit IV.
    ///
    /// Read value: [`u32`]; Write value: [`u32`]
    pub fn iv(&self) -> ureg::Array<4, ureg::RegRef<crate::doe::meta::Iv, &TMmio>> {
        unsafe {
            ureg::Array::new_with_mmio(
                self.ptr.wrapping_add(0 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Controls the de-obfuscation command to run
    ///
    /// Read value: [`doe::regs::CtrlReadVal`]; Write value: [`doe::regs::CtrlWriteVal`]
    pub fn ctrl(&self) -> ureg::RegRef<crate::doe::meta::Ctrl, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x10 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Provides status of the DOE block and the status of the flows it runs
    ///
    /// Read value: [`doe::regs::StatusReadVal`]; Write value: [`doe::regs::StatusWriteVal`]
    pub fn status(&self) -> ureg::RegRef<crate::doe::meta::Status, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x14 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    pub fn intr_block_rf(&self) -> IntrBlockRfBlock<&TMmio> {
        IntrBlockRfBlock {
            ptr: unsafe { self.ptr.add(0x800 / core::mem::size_of::<u32>()) },
            mmio: core::borrow::Borrow::borrow(&self.mmio),
        }
    }
}
#[derive(Clone, Copy)]
pub struct IntrBlockRfBlock<TMmio: ureg::Mmio + core::borrow::Borrow<TMmio>> {
    ptr: *mut u32,
    mmio: TMmio,
}
impl<TMmio: ureg::Mmio> IntrBlockRfBlock<TMmio> {
    /// Dedicated register with one bit for each event type that may produce an interrupt.
    ///
    /// Read value: [`sha512_acc::regs::GlobalIntrEnTReadVal`]; Write value: [`sha512_acc::regs::GlobalIntrEnTWriteVal`]
    pub fn global_intr_en_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfGlobalIntrEnR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Dedicated register with one bit for each event that may produce an interrupt.
    ///
    /// Read value: [`sha512_acc::regs::ErrorIntrEnTReadVal`]; Write value: [`sha512_acc::regs::ErrorIntrEnTWriteVal`]
    pub fn error_intr_en_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfErrorIntrEnR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(4 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Dedicated register with one bit for each event that may produce an interrupt.
    ///
    /// Read value: [`sha512_acc::regs::NotifIntrEnTReadVal`]; Write value: [`sha512_acc::regs::NotifIntrEnTWriteVal`]
    pub fn notif_intr_en_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfNotifIntrEnR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(8 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Single bit indicating occurrence of any interrupt event
    /// of a given type. E.g. Notifications and Errors may drive
    /// to two separate interrupt registers. There may be
    /// multiple sources of Notifications or Errors that are
    /// aggregated into a single interrupt pin for that
    /// respective type. That pin feeds through this register
    /// in order to apply a global enablement of that interrupt
    /// event type.
    /// Nonsticky assertion.
    ///
    /// Read value: [`sha512_acc::regs::GlobalIntrTReadVal`]; Write value: [`sha512_acc::regs::GlobalIntrTWriteVal`]
    pub fn error_global_intr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfErrorGlobalIntrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0xc / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Single bit indicating occurrence of any interrupt event
    /// of a given type. E.g. Notifications and Errors may drive
    /// to two separate interrupt registers. There may be
    /// multiple sources of Notifications or Errors that are
    /// aggregated into a single interrupt pin for that
    /// respective type. That pin feeds through this register
    /// in order to apply a global enablement of that interrupt
    /// event type.
    /// Nonsticky assertion.
    ///
    /// Read value: [`sha512_acc::regs::GlobalIntrTReadVal`]; Write value: [`sha512_acc::regs::GlobalIntrTWriteVal`]
    pub fn notif_global_intr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfNotifGlobalIntrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x10 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Single bit indicating occurrence of each interrupt event.
    /// Sticky, level assertion, write-1-to-clear.
    ///
    /// Read value: [`sha512_acc::regs::ErrorIntrTReadVal`]; Write value: [`sha512_acc::regs::ErrorIntrTWriteVal`]
    pub fn error_internal_intr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfErrorInternalIntrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x14 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Single bit indicating occurrence of each interrupt event.
    /// Sticky, level assertion, write-1-to-clear.
    ///
    /// Read value: [`sha512_acc::regs::NotifIntrTReadVal`]; Write value: [`sha512_acc::regs::NotifIntrTWriteVal`]
    pub fn notif_internal_intr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfNotifInternalIntrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x18 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Single bit for each interrupt event allows SW to manually
    /// trigger occurrence of that event. Upon SW write, the bit
    /// will pulse for 1 cycle then clear to 0.
    ///
    /// Read value: [`sha512_acc::regs::ErrorIntrTrigTReadVal`]; Write value: [`sha512_acc::regs::ErrorIntrTrigTWriteVal`]
    pub fn error_intr_trig_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfErrorIntrTrigR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x1c / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Single bit for each interrupt event allows SW to manually
    /// trigger occurrence of that event. Upon SW write, the bit
    /// will pulse for 1 cycle then clear to 0.
    ///
    /// Read value: [`sha512_acc::regs::NotifIntrTrigTReadVal`]; Write value: [`sha512_acc::regs::NotifIntrTrigTWriteVal`]
    pub fn notif_intr_trig_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfNotifIntrTrigR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x20 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Provides statistics about the number of events that have
    /// occurred.
    /// Will not overflow ('incrsaturate').
    ///
    /// Read value: [`u32`]; Write value: [`u32`]
    pub fn error0_intr_count_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError0IntrCountR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x100 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Provides statistics about the number of events that have
    /// occurred.
    /// Will not overflow ('incrsaturate').
    ///
    /// Read value: [`u32`]; Write value: [`u32`]
    pub fn error1_intr_count_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError1IntrCountR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x104 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Provides statistics about the number of events that have
    /// occurred.
    /// Will not overflow ('incrsaturate').
    ///
    /// Read value: [`u32`]; Write value: [`u32`]
    pub fn error2_intr_count_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError2IntrCountR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x108 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Provides statistics about the number of events that have
    /// occurred.
    /// Will not overflow ('incrsaturate').
    ///
    /// Read value: [`u32`]; Write value: [`u32`]
    pub fn error3_intr_count_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError3IntrCountR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x10c / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Provides statistics about the number of events that have
    /// occurred.
    /// Will not overflow ('incrsaturate').
    ///
    /// Read value: [`u32`]; Write value: [`u32`]
    pub fn notif_cmd_done_intr_count_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfNotifCmdDoneIntrCountR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x180 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Trigger the event counter to increment based on observing
    /// the rising edge of an interrupt event input from the
    /// Hardware. The same input signal that causes an interrupt
    /// event to be set (sticky) also causes this signal to pulse
    /// for 1 clock cycle, resulting in the event counter
    /// incrementing by 1 for every interrupt event.
    /// This is implemented as a down-counter (1-bit) that will
    /// decrement immediately on being set - resulting in a pulse
    ///
    /// Read value: [`sha512_acc::regs::IntrCountIncrTReadVal`]; Write value: [`sha512_acc::regs::IntrCountIncrTWriteVal`]
    pub fn error0_intr_count_incr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError0IntrCountIncrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x200 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Trigger the event counter to increment based on observing
    /// the rising edge of an interrupt event input from the
    /// Hardware. The same input signal that causes an interrupt
    /// event to be set (sticky) also causes this signal to pulse
    /// for 1 clock cycle, resulting in the event counter
    /// incrementing by 1 for every interrupt event.
    /// This is implemented as a down-counter (1-bit) that will
    /// decrement immediately on being set - resulting in a pulse
    ///
    /// Read value: [`sha512_acc::regs::IntrCountIncrTReadVal`]; Write value: [`sha512_acc::regs::IntrCountIncrTWriteVal`]
    pub fn error1_intr_count_incr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError1IntrCountIncrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x204 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Trigger the event counter to increment based on observing
    /// the rising edge of an interrupt event input from the
    /// Hardware. The same input signal that causes an interrupt
    /// event to be set (sticky) also causes this signal to pulse
    /// for 1 clock cycle, resulting in the event counter
    /// incrementing by 1 for every interrupt event.
    /// This is implemented as a down-counter (1-bit) that will
    /// decrement immediately on being set - resulting in a pulse
    ///
    /// Read value: [`sha512_acc::regs::IntrCountIncrTReadVal`]; Write value: [`sha512_acc::regs::IntrCountIncrTWriteVal`]
    pub fn error2_intr_count_incr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError2IntrCountIncrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x208 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Trigger the event counter to increment based on observing
    /// the rising edge of an interrupt event input from the
    /// Hardware. The same input signal that causes an interrupt
    /// event to be set (sticky) also causes this signal to pulse
    /// for 1 clock cycle, resulting in the event counter
    /// incrementing by 1 for every interrupt event.
    /// This is implemented as a down-counter (1-bit) that will
    /// decrement immediately on being set - resulting in a pulse
    ///
    /// Read value: [`sha512_acc::regs::IntrCountIncrTReadVal`]; Write value: [`sha512_acc::regs::IntrCountIncrTWriteVal`]
    pub fn error3_intr_count_incr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfError3IntrCountIncrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x20c / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
    /// Trigger the event counter to increment based on observing
    /// the rising edge of an interrupt event input from the
    /// Hardware. The same input signal that causes an interrupt
    /// event to be set (sticky) also causes this signal to pulse
    /// for 1 clock cycle, resulting in the event counter
    /// incrementing by 1 for every interrupt event.
    /// This is implemented as a down-counter (1-bit) that will
    /// decrement immediately on being set - resulting in a pulse
    ///
    /// Read value: [`sha512_acc::regs::IntrCountIncrTReadVal`]; Write value: [`sha512_acc::regs::IntrCountIncrTWriteVal`]
    pub fn notif_cmd_done_intr_count_incr_r(
        &self,
    ) -> ureg::RegRef<crate::doe::meta::IntrBlockRfNotifCmdDoneIntrCountIncrR, &TMmio> {
        unsafe {
            ureg::RegRef::new_with_mmio(
                self.ptr.wrapping_add(0x210 / core::mem::size_of::<u32>()),
                core::borrow::Borrow::borrow(&self.mmio),
            )
        }
    }
}
pub mod regs {
    //! Types that represent the values held by registers.
    #[derive(Clone, Copy)]
    pub struct CtrlReadVal(u32);
    impl CtrlReadVal {
        /// Indicates the command for DOE to run
        #[inline(always)]
        pub fn cmd(&self) -> super::enums::DoeCmdE {
            super::enums::DoeCmdE::try_from((self.0 >> 0) & 3).unwrap()
        }
        /// Key Vault entry to store the result.
        #[inline(always)]
        pub fn dest(&self) -> u32 {
            (self.0 >> 2) & 0x1f
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> CtrlWriteVal {
            CtrlWriteVal(self.0)
        }
    }
    impl From<u32> for CtrlReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<CtrlReadVal> for u32 {
        fn from(val: CtrlReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct CtrlWriteVal(u32);
    impl CtrlWriteVal {
        /// Indicates the command for DOE to run
        #[inline(always)]
        pub fn cmd(
            self,
            f: impl FnOnce(super::enums::selector::DoeCmdESelector) -> super::enums::DoeCmdE,
        ) -> Self {
            Self(
                (self.0 & !(3 << 0))
                    | (u32::from(f(super::enums::selector::DoeCmdESelector())) << 0),
            )
        }
        /// Key Vault entry to store the result.
        #[inline(always)]
        pub fn dest(self, val: u32) -> Self {
            Self((self.0 & !(0x1f << 2)) | ((val & 0x1f) << 2))
        }
    }
    impl From<u32> for CtrlWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<CtrlWriteVal> for u32 {
        fn from(val: CtrlWriteVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct StatusReadVal(u32);
    impl StatusReadVal {
        /// Status ready bit - Indicates if the core is ready to take a control command and process the block.
        #[inline(always)]
        pub fn ready(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Status valid bit - Indicates if the process is done and the results have been stored in the keyvault.
        #[inline(always)]
        pub fn valid(&self) -> bool {
            ((self.0 >> 1) & 1) != 0
        }
        /// UDS Flow Completed
        #[inline(always)]
        pub fn uds_flow_done(&self) -> bool {
            ((self.0 >> 2) & 1) != 0
        }
        /// FE flow completed
        #[inline(always)]
        pub fn fe_flow_done(&self) -> bool {
            ((self.0 >> 3) & 1) != 0
        }
        /// Clear Secrets flow completed
        #[inline(always)]
        pub fn deobf_secrets_cleared(&self) -> bool {
            ((self.0 >> 4) & 1) != 0
        }
    }
    impl From<u32> for StatusReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<StatusReadVal> for u32 {
        fn from(val: StatusReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct ErrorIntrEnTReadVal(u32);
    impl ErrorIntrEnTReadVal {
        /// Enable bit for Event 0
        #[inline(always)]
        pub fn error0_en(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Enable bit for Event 1
        #[inline(always)]
        pub fn error1_en(&self) -> bool {
            ((self.0 >> 1) & 1) != 0
        }
        /// Enable bit for Event 2
        #[inline(always)]
        pub fn error2_en(&self) -> bool {
            ((self.0 >> 2) & 1) != 0
        }
        /// Enable bit for Event 3
        #[inline(always)]
        pub fn error3_en(&self) -> bool {
            ((self.0 >> 3) & 1) != 0
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> ErrorIntrEnTWriteVal {
            ErrorIntrEnTWriteVal(self.0)
        }
    }
    impl From<u32> for ErrorIntrEnTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<ErrorIntrEnTReadVal> for u32 {
        fn from(val: ErrorIntrEnTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct ErrorIntrEnTWriteVal(u32);
    impl ErrorIntrEnTWriteVal {
        /// Enable bit for Event 0
        #[inline(always)]
        pub fn error0_en(self, val: bool) -> Self {
            Self((self.0 & !(1 << 0)) | (u32::from(val) << 0))
        }
        /// Enable bit for Event 1
        #[inline(always)]
        pub fn error1_en(self, val: bool) -> Self {
            Self((self.0 & !(1 << 1)) | (u32::from(val) << 1))
        }
        /// Enable bit for Event 2
        #[inline(always)]
        pub fn error2_en(self, val: bool) -> Self {
            Self((self.0 & !(1 << 2)) | (u32::from(val) << 2))
        }
        /// Enable bit for Event 3
        #[inline(always)]
        pub fn error3_en(self, val: bool) -> Self {
            Self((self.0 & !(1 << 3)) | (u32::from(val) << 3))
        }
    }
    impl From<u32> for ErrorIntrEnTWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<ErrorIntrEnTWriteVal> for u32 {
        fn from(val: ErrorIntrEnTWriteVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct ErrorIntrTReadVal(u32);
    impl ErrorIntrTReadVal {
        /// Interrupt Event 0 status bit
        #[inline(always)]
        pub fn error0_sts(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Interrupt Event 1 status bit
        #[inline(always)]
        pub fn error1_sts(&self) -> bool {
            ((self.0 >> 1) & 1) != 0
        }
        /// Interrupt Event 2 status bit
        #[inline(always)]
        pub fn error2_sts(&self) -> bool {
            ((self.0 >> 2) & 1) != 0
        }
        /// Interrupt Event 3 status bit
        #[inline(always)]
        pub fn error3_sts(&self) -> bool {
            ((self.0 >> 3) & 1) != 0
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> ErrorIntrTWriteVal {
            ErrorIntrTWriteVal(self.0)
        }
    }
    impl From<u32> for ErrorIntrTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<ErrorIntrTReadVal> for u32 {
        fn from(val: ErrorIntrTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct ErrorIntrTWriteVal(u32);
    impl ErrorIntrTWriteVal {
        /// Interrupt Event 0 status bit
        #[inline(always)]
        pub fn error0_sts(self, val: bool) -> Self {
            Self((self.0 & !(1 << 0)) | (u32::from(val) << 0))
        }
        /// Interrupt Event 1 status bit
        #[inline(always)]
        pub fn error1_sts(self, val: bool) -> Self {
            Self((self.0 & !(1 << 1)) | (u32::from(val) << 1))
        }
        /// Interrupt Event 2 status bit
        #[inline(always)]
        pub fn error2_sts(self, val: bool) -> Self {
            Self((self.0 & !(1 << 2)) | (u32::from(val) << 2))
        }
        /// Interrupt Event 3 status bit
        #[inline(always)]
        pub fn error3_sts(self, val: bool) -> Self {
            Self((self.0 & !(1 << 3)) | (u32::from(val) << 3))
        }
    }
    impl From<u32> for ErrorIntrTWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<ErrorIntrTWriteVal> for u32 {
        fn from(val: ErrorIntrTWriteVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct ErrorIntrTrigTReadVal(u32);
    impl ErrorIntrTrigTReadVal {
        /// Interrupt Trigger 0 bit
        #[inline(always)]
        pub fn error0_trig(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Interrupt Trigger 1 bit
        #[inline(always)]
        pub fn error1_trig(&self) -> bool {
            ((self.0 >> 1) & 1) != 0
        }
        /// Interrupt Trigger 2 bit
        #[inline(always)]
        pub fn error2_trig(&self) -> bool {
            ((self.0 >> 2) & 1) != 0
        }
        /// Interrupt Trigger 3 bit
        #[inline(always)]
        pub fn error3_trig(&self) -> bool {
            ((self.0 >> 3) & 1) != 0
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> ErrorIntrTrigTWriteVal {
            ErrorIntrTrigTWriteVal(self.0)
        }
    }
    impl From<u32> for ErrorIntrTrigTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<ErrorIntrTrigTReadVal> for u32 {
        fn from(val: ErrorIntrTrigTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct ErrorIntrTrigTWriteVal(u32);
    impl ErrorIntrTrigTWriteVal {
        /// Interrupt Trigger 0 bit
        #[inline(always)]
        pub fn error0_trig(self, val: bool) -> Self {
            Self((self.0 & !(1 << 0)) | (u32::from(val) << 0))
        }
        /// Interrupt Trigger 1 bit
        #[inline(always)]
        pub fn error1_trig(self, val: bool) -> Self {
            Self((self.0 & !(1 << 1)) | (u32::from(val) << 1))
        }
        /// Interrupt Trigger 2 bit
        #[inline(always)]
        pub fn error2_trig(self, val: bool) -> Self {
            Self((self.0 & !(1 << 2)) | (u32::from(val) << 2))
        }
        /// Interrupt Trigger 3 bit
        #[inline(always)]
        pub fn error3_trig(self, val: bool) -> Self {
            Self((self.0 & !(1 << 3)) | (u32::from(val) << 3))
        }
    }
    impl From<u32> for ErrorIntrTrigTWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<ErrorIntrTrigTWriteVal> for u32 {
        fn from(val: ErrorIntrTrigTWriteVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct GlobalIntrEnTReadVal(u32);
    impl GlobalIntrEnTReadVal {
        /// Global enable bit for all events of type 'Error'
        #[inline(always)]
        pub fn error_en(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Global enable bit for all events of type 'Notification'
        #[inline(always)]
        pub fn notif_en(&self) -> bool {
            ((self.0 >> 1) & 1) != 0
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> GlobalIntrEnTWriteVal {
            GlobalIntrEnTWriteVal(self.0)
        }
    }
    impl From<u32> for GlobalIntrEnTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<GlobalIntrEnTReadVal> for u32 {
        fn from(val: GlobalIntrEnTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct GlobalIntrEnTWriteVal(u32);
    impl GlobalIntrEnTWriteVal {
        /// Global enable bit for all events of type 'Error'
        #[inline(always)]
        pub fn error_en(self, val: bool) -> Self {
            Self((self.0 & !(1 << 0)) | (u32::from(val) << 0))
        }
        /// Global enable bit for all events of type 'Notification'
        #[inline(always)]
        pub fn notif_en(self, val: bool) -> Self {
            Self((self.0 & !(1 << 1)) | (u32::from(val) << 1))
        }
    }
    impl From<u32> for GlobalIntrEnTWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<GlobalIntrEnTWriteVal> for u32 {
        fn from(val: GlobalIntrEnTWriteVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct GlobalIntrTReadVal(u32);
    impl GlobalIntrTReadVal {
        /// Interrupt Event Aggregation status bit
        #[inline(always)]
        pub fn agg_sts(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
    }
    impl From<u32> for GlobalIntrTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<GlobalIntrTReadVal> for u32 {
        fn from(val: GlobalIntrTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct IntrCountIncrTReadVal(u32);
    impl IntrCountIncrTReadVal {
        /// Pulse mirrors interrupt event occurrence
        #[inline(always)]
        pub fn pulse(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
    }
    impl From<u32> for IntrCountIncrTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<IntrCountIncrTReadVal> for u32 {
        fn from(val: IntrCountIncrTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct NotifIntrEnTReadVal(u32);
    impl NotifIntrEnTReadVal {
        /// Enable bit for Command Done Interrupt
        #[inline(always)]
        pub fn notif_cmd_done_en(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> NotifIntrEnTWriteVal {
            NotifIntrEnTWriteVal(self.0)
        }
    }
    impl From<u32> for NotifIntrEnTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<NotifIntrEnTReadVal> for u32 {
        fn from(val: NotifIntrEnTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct NotifIntrEnTWriteVal(u32);
    impl NotifIntrEnTWriteVal {
        /// Enable bit for Command Done Interrupt
        #[inline(always)]
        pub fn notif_cmd_done_en(self, val: bool) -> Self {
            Self((self.0 & !(1 << 0)) | (u32::from(val) << 0))
        }
    }
    impl From<u32> for NotifIntrEnTWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<NotifIntrEnTWriteVal> for u32 {
        fn from(val: NotifIntrEnTWriteVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct NotifIntrTReadVal(u32);
    impl NotifIntrTReadVal {
        /// Command Done Interrupt status bit
        #[inline(always)]
        pub fn notif_cmd_done_sts(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> NotifIntrTWriteVal {
            NotifIntrTWriteVal(self.0)
        }
    }
    impl From<u32> for NotifIntrTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<NotifIntrTReadVal> for u32 {
        fn from(val: NotifIntrTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct NotifIntrTWriteVal(u32);
    impl NotifIntrTWriteVal {
        /// Command Done Interrupt status bit
        #[inline(always)]
        pub fn notif_cmd_done_sts(self, val: bool) -> Self {
            Self((self.0 & !(1 << 0)) | (u32::from(val) << 0))
        }
    }
    impl From<u32> for NotifIntrTWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<NotifIntrTWriteVal> for u32 {
        fn from(val: NotifIntrTWriteVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct NotifIntrTrigTReadVal(u32);
    impl NotifIntrTrigTReadVal {
        /// Interrupt Trigger 0 bit
        #[inline(always)]
        pub fn notif_cmd_done_trig(&self) -> bool {
            ((self.0 >> 0) & 1) != 0
        }
        /// Construct a WriteVal that can be used to modify the contents of this register value.
        pub fn modify(self) -> NotifIntrTrigTWriteVal {
            NotifIntrTrigTWriteVal(self.0)
        }
    }
    impl From<u32> for NotifIntrTrigTReadVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<NotifIntrTrigTReadVal> for u32 {
        fn from(val: NotifIntrTrigTReadVal) -> u32 {
            val.0
        }
    }
    #[derive(Clone, Copy)]
    pub struct NotifIntrTrigTWriteVal(u32);
    impl NotifIntrTrigTWriteVal {
        /// Interrupt Trigger 0 bit
        #[inline(always)]
        pub fn notif_cmd_done_trig(self, val: bool) -> Self {
            Self((self.0 & !(1 << 0)) | (u32::from(val) << 0))
        }
    }
    impl From<u32> for NotifIntrTrigTWriteVal {
        fn from(val: u32) -> Self {
            Self(val)
        }
    }
    impl From<NotifIntrTrigTWriteVal> for u32 {
        fn from(val: NotifIntrTrigTWriteVal) -> u32 {
            val.0
        }
    }
}
pub mod enums {
    //! Enumerations used by some register fields.
    #[derive(Clone, Copy, Eq, PartialEq)]
    #[repr(u32)]
    pub enum DoeCmdE {
        DoeIdle = 0,
        DoeUds = 1,
        DoeFe = 2,
        DoeClearObfSecrets = 3,
    }
    impl DoeCmdE {
        #[inline(always)]
        pub fn doe_idle(&self) -> bool {
            *self == Self::DoeIdle
        }
        #[inline(always)]
        pub fn doe_uds(&self) -> bool {
            *self == Self::DoeUds
        }
        #[inline(always)]
        pub fn doe_fe(&self) -> bool {
            *self == Self::DoeFe
        }
        #[inline(always)]
        pub fn doe_clear_obf_secrets(&self) -> bool {
            *self == Self::DoeClearObfSecrets
        }
    }
    impl TryFrom<u32> for DoeCmdE {
        type Error = ();
        #[inline(always)]
        fn try_from(val: u32) -> Result<DoeCmdE, ()> {
            if val < 4 {
                Ok(unsafe { core::mem::transmute(val) })
            } else {
                Err(())
            }
        }
    }
    impl From<DoeCmdE> for u32 {
        fn from(val: DoeCmdE) -> Self {
            val as u32
        }
    }
    pub mod selector {
        pub struct DoeCmdESelector();
        impl DoeCmdESelector {
            #[inline(always)]
            pub fn doe_idle(&self) -> super::DoeCmdE {
                super::DoeCmdE::DoeIdle
            }
            #[inline(always)]
            pub fn doe_uds(&self) -> super::DoeCmdE {
                super::DoeCmdE::DoeUds
            }
            #[inline(always)]
            pub fn doe_fe(&self) -> super::DoeCmdE {
                super::DoeCmdE::DoeFe
            }
            #[inline(always)]
            pub fn doe_clear_obf_secrets(&self) -> super::DoeCmdE {
                super::DoeCmdE::DoeClearObfSecrets
            }
        }
    }
}
pub mod meta {
    //! Additional metadata needed by ureg.
    pub type Iv = ureg::ReadWriteReg32<0, u32, u32>;
    pub type Ctrl =
        ureg::ReadWriteReg32<0, crate::doe::regs::CtrlReadVal, crate::doe::regs::CtrlWriteVal>;
    pub type Status = ureg::ReadOnlyReg32<crate::doe::regs::StatusReadVal>;
    pub type IntrBlockRfGlobalIntrEnR = ureg::ReadWriteReg32<
        0,
        crate::sha512_acc::regs::GlobalIntrEnTReadVal,
        crate::sha512_acc::regs::GlobalIntrEnTWriteVal,
    >;
    pub type IntrBlockRfErrorIntrEnR = ureg::ReadWriteReg32<
        0,
        crate::sha512_acc::regs::ErrorIntrEnTReadVal,
        crate::sha512_acc::regs::ErrorIntrEnTWriteVal,
    >;
    pub type IntrBlockRfNotifIntrEnR = ureg::ReadWriteReg32<
        0,
        crate::sha512_acc::regs::NotifIntrEnTReadVal,
        crate::sha512_acc::regs::NotifIntrEnTWriteVal,
    >;
    pub type IntrBlockRfErrorGlobalIntrR =
        ureg::ReadOnlyReg32<crate::sha512_acc::regs::GlobalIntrTReadVal>;
    pub type IntrBlockRfNotifGlobalIntrR =
        ureg::ReadOnlyReg32<crate::sha512_acc::regs::GlobalIntrTReadVal>;
    pub type IntrBlockRfErrorInternalIntrR = ureg::ReadWriteReg32<
        0,
        crate::sha512_acc::regs::ErrorIntrTReadVal,
        crate::sha512_acc::regs::ErrorIntrTWriteVal,
    >;
    pub type IntrBlockRfNotifInternalIntrR = ureg::ReadWriteReg32<
        0,
        crate::sha512_acc::regs::NotifIntrTReadVal,
        crate::sha512_acc::regs::NotifIntrTWriteVal,
    >;
    pub type IntrBlockRfErrorIntrTrigR = ureg::ReadWriteReg32<
        0,
        crate::sha512_acc::regs::ErrorIntrTrigTReadVal,
        crate::sha512_acc::regs::ErrorIntrTrigTWriteVal,
    >;
    pub type IntrBlockRfNotifIntrTrigR = ureg::ReadWriteReg32<
        0,
        crate::sha512_acc::regs::NotifIntrTrigTReadVal,
        crate::sha512_acc::regs::NotifIntrTrigTWriteVal,
    >;
    pub type IntrBlockRfError0IntrCountR = ureg::ReadWriteReg32<0, u32, u32>;
    pub type IntrBlockRfError1IntrCountR = ureg::ReadWriteReg32<0, u32, u32>;
    pub type IntrBlockRfError2IntrCountR = ureg::ReadWriteReg32<0, u32, u32>;
    pub type IntrBlockRfError3IntrCountR = ureg::ReadWriteReg32<0, u32, u32>;
    pub type IntrBlockRfNotifCmdDoneIntrCountR = ureg::ReadWriteReg32<0, u32, u32>;
    pub type IntrBlockRfError0IntrCountIncrR =
        ureg::ReadOnlyReg32<crate::sha512_acc::regs::IntrCountIncrTReadVal>;
    pub type IntrBlockRfError1IntrCountIncrR =
        ureg::ReadOnlyReg32<crate::sha512_acc::regs::IntrCountIncrTReadVal>;
    pub type IntrBlockRfError2IntrCountIncrR =
        ureg::ReadOnlyReg32<crate::sha512_acc::regs::IntrCountIncrTReadVal>;
    pub type IntrBlockRfError3IntrCountIncrR =
        ureg::ReadOnlyReg32<crate::sha512_acc::regs::IntrCountIncrTReadVal>;
    pub type IntrBlockRfNotifCmdDoneIntrCountIncrR =
        ureg::ReadOnlyReg32<crate::sha512_acc::regs::IntrCountIncrTReadVal>;
}
