# Debug Voucher System - Step by Step

I've added debugging code to help us understand what's happening. Follow these steps EXACTLY:

## Step 1: Clear Local Storage and Run App

1. **The flag is already set to TRUE** in `lib/main.dart` (line 32)
2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Watch the console output** when the app starts. You should see:
   ```
   🧹 CLEARING OLD LOCAL STORAGE BOOKINGS...
   ✅ Local storage cleared! App now uses Supabase only.
   ```

4. **If you see that message:**
   - Stop the app
   - Open `lib/main.dart`
   - Change line 32: `const bool clearOldLocalStorage = false;`
   - Save and run the app again

## Step 2: Check if Bookings Load from Supabase

1. **Log in as a technician**
2. **Go to the Jobs screen**
3. **Look at the console output** - you should see:
   ```
   🔍 ACTIVE JOBS: Found X total bookings from Supabase
     - Booking abc123: In Progress
       Promo: FIRST20, Discount: 20%
       Original: ₱1000, Final: ₱800
   ```

**IMPORTANT QUESTIONS TO ANSWER:**

- ❓ **Do you see any bookings?** (yes/no)
- ❓ **How many bookings are shown?** (number)
- ❓ **Do the bookings have discount info?** (Promo Code, Discount, Original Price)
- ❓ **Are the values correct?** (yes/no)

## Step 3: Test Edit Dialog

1. **Click on a booking** that has a discount
2. **Click the Edit button**
3. **Look at the console output** - you should see:
   ```
   🔍 EDIT DIALOG OPENED:
     Booking ID: abc123
     Status: In Progress
     Diagnostic Notes: Device: Mobile Phone
   Model: iPhone 13
   Problem: Screen broken
   Promo Code: FIRST20
   Original Price: ₱1000.00
   Discount: 20%
     Customer Details: Device: Mobile Phone
   Model: iPhone 13
   Problem: Screen broken
   Promo Code: FIRST20
   Original Price: ₱1000.00
   Discount: 20%
     Technician Notes: null
     Promo Code: FIRST20
     Discount: 20%
     Original Price: ₱1000.00
     Final Cost: 800.0
     Estimated Cost: 1000.0
   ```

**IMPORTANT QUESTIONS TO ANSWER:**

- ❓ **Does the dialog show customer notes in the gray box?** (yes/no)
- ❓ **Is the "Technician Notes" text field EMPTY?** (yes/no)
- ❓ **What text appears in the Technician Notes field?** (copy exactly what you see)

## Step 4: Test Price Adjustment

1. **In the edit dialog:**
   - Add technician notes: "Battery replacement needed"
   - Add price adjustment: 5000
   - Click "Update Booking"

2. **Look at the console output:**
   ```
   💾 SAVING BOOKING UPDATE:
     Booking ID: abc123
     Technician Notes: Battery replacement needed
     Price Adjustment: 5000.0
   ✅ BOOKING SAVED SUCCESSFULLY
   ```

3. **Check the booking details again:**
   - What is the new final cost shown?
   - Expected: ₱4800 (₱6000 original - 20% discount)
   - Actual: ?

**IMPORTANT QUESTIONS TO ANSWER:**

- ❓ **Did you see the save success message?** (yes/no)
- ❓ **What is the new final cost shown?** (number)
- ❓ **Is it correct (₱4800)?** (yes/no)
- ❓ **If not, what is shown?** (number)

## Step 5: Send Me the Console Output

**Copy and paste the ENTIRE console output** from when you:
1. Started the app
2. Went to technician screen
3. Opened a booking
4. Clicked edit
5. Saved changes

Send me everything that starts with 🔍, 💾, or ✅

---

## What to Send Me

Please send me:

1. ✅ **Console output from Step 1** (clearing storage)
2. ✅ **Console output from Step 2** (loading bookings)
3. ✅ **Console output from Step 3** (opening edit dialog)
4. ✅ **Console output from Step 4** (saving changes)
5. ✅ **Screenshot of the edit dialog** showing:
   - Customer Notes section
   - Technician Notes field (is it empty?)
   - Price adjustment field
6. ✅ **Screenshot of the booking after saving** showing the final cost

With this information, I can tell you EXACTLY what's wrong!

---

## Quick Checklist

Before running, verify:
- [ ] `clearOldLocalStorage = true` in lib/main.dart (line 32)
- [ ] You have a booking in Supabase with a discount
- [ ] You're logged in as a technician
- [ ] Console is visible and you can see output

After first run:
- [ ] Change `clearOldLocalStorage = false`
- [ ] Run app again
- [ ] Follow Steps 2-5 above
